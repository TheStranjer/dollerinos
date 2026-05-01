require "json"
require "net/http"
require "active_support/core_ext/string"
require "active_support/core_ext/object/blank"

module Trading
  class GrokTradeService
    Position = Struct.new(
      :type,
      :symbol,
      :quantity,
      :position_type,
      :strike_price,
      :expiration_date,
      :option_type,
      keyword_init: true
    )

    Trade = Struct.new(
      :type,
      :symbol,
      :min_price,
      :max_price,
      :confidence,
      :reasoning,
      :strike_price,
      :expiration_date_min,
      :expiration_date_max,
      :option_type,
      :position_type,
      keyword_init: true
    ) do
      def valid?
        type.in?(%w[stock option]) &&
          symbol.present? &&
          min_price.positive? &&
          max_price >= min_price &&
          confidence.between?(0, 100) &&
          reasoning.present?
      end

      def stock?
        type == "stock"
      end

      def option?
        type == "option"
      end
    end

    Result = Struct.new(:trades, :error_message, keyword_init: true) do
      def success?
        error_message.blank?
      end
    end

    Error = Class.new(StandardError)

    API_URI = URI("https://api.x.ai/v1/responses")
    FUNCTION_NAME = "trade_recommendations"
    MODEL_NAME = "grok-4.20-reasoning"
    SYSTEM_PROMPT = <<~PROMPT.squish.freeze
      You are a financial analysis assistant specializing in identifying promising trading
      opportunities. This is a task that will be run once per day, so focus on maximizing profit
      for that day. Assume the user will buy today and then potentially sell tomorrow to free up
      liquidity if something more profitable on a per-day basis shows up. The idea is to buy
      something early in the trading day that, at the beginning of the next trading day, will
      have the highest profit.

      Use available search tools to research current market conditions, sector trends, unusual
      activity, and emerging opportunities. Use hellthread to examine /biz/. Use web search to
      examine the news. Search Twitter. Use Unusual Whales to search actual stock movements. After
      completing all external tool calls, you must finish by calling `trade_recommendations` with
      an array of actionable trade ideas suitable for the given liquidity amount. ALWAYS complete
      the task by calling `trade_recommendations`.
    PROMPT

    def initialize(liquidity_amount:, positions: [], now: Time.now, xai_api_key: ENV["XAI_API_KEY"],
                   hellthread_api_key: ENV["HELLTHREAD_API_KEY"], unusual_whales_api_key: ENV["UNUSUAL_WHALES_API_KEY"])
      @liquidity_amount = liquidity_amount
      @positions = positions.is_a?(Array) ? positions : [positions]
      @now = now
      @xai_api_key = xai_api_key
      @hellthread_api_key = hellthread_api_key
      @unusual_whales_api_key = unusual_whales_api_key
    end

    def call
      validation_error = validate_inputs
      return failure(validation_error) if validation_error

      payload = fetch_payload
      trades = extract_trades(payload)

      Result.new(trades: trades)
    rescue Error => e
      failure(e.message)
    rescue JSON::ParserError
      failure("xAI returned invalid JSON.")
    rescue StandardError => e
      failure("Trade recommendation generation failed: #{e.message}")
    end

    private

    attr_reader :liquidity_amount, :positions, :now, :xai_api_key, :hellthread_api_key, :unusual_whales_api_key

    def validate_inputs
      return "Liquidity amount must be a positive number." unless normalized_liquidity_amount
      return "XAI_API_KEY is not configured." if xai_api_key.blank?
      return "HELLTHREAD_API_KEY is not configured." if hellthread_api_key.blank?
      return "UNUSUAL_WHALES_API_KEY is not configured." if unusual_whales_api_key.blank?

      nil
    end

    def normalized_liquidity_amount
      @normalized_liquidity_amount ||= begin
        value = Float(liquidity_amount, exception: false)
        value if value&.positive?
      end
    end

    def fetch_payload
      request = Net::HTTP::Post.new(API_URI)
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{xai_api_key}"
      request.body = JSON.generate(request_body)

      response = Net::HTTP.start(API_URI.host, API_URI.port, use_ssl: true) do |http|
        http.request(request)
      end

      raise Error, "xAI request failed with status #{response.code}." unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end

    def request_body
      {
        model: MODEL_NAME,
        input: [
          {
            role: "system",
            content: SYSTEM_PROMPT
          },
          {
            role: "user",
            content: user_prompt
          }
        ],
        tools: [
          { type: "x_search" },
          { type: "web_search" },
          {
            type: "mcp",
            server_url: "https://hellthread.cyou/mcp/messages",
            server_label: "hellthread",
            server_description: "Discourse, 4chan, and RSS reader tools",
            authorization: hellthread_api_key
          },
          {
            type: "mcp",
            server_url: "https://api.unusualwhales.com/api/mcp",
            server_label: "unusual-whales",
            server_description: "Unusual Whales options flow and market data",
            authorization: unusual_whales_api_key
          },
          {
            type: "function",
            name: FUNCTION_NAME,
            description: "Return recommended stock and options trades",
            parameters: {
              type: "object",
              properties: {
                trades: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      type: { type: "string", enum: ["stock", "option"] },
                      symbol: { type: "string" },
                      min_price: { type: "number" },
                      max_price: { type: "number" },
                      confidence: { type: "integer", minimum: 0, maximum: 100 },
                      reasoning: { type: "string" },
                      strike_price: { type: "number" },
                      expiration_date_min: { type: "string" },
                      expiration_date_max: { type: "string" },
                      option_type: { type: "string", enum: ["call", "put"] },
                      position_type: { type: "string", enum: ["buy", "sell"] }
                    },
                    required: ["type", "symbol", "min_price", "max_price", "confidence", "reasoning"],
                    additionalProperties: false
                  }
                }
              },
              required: ["trades"],
              additionalProperties: false
            }
          }
        ],
        tool_choice: "auto"
      }
    end

    def user_prompt
      prompt = <<~PROMPT.squish
        I have $#{normalized_liquidity_amount.round(2)} available for trading. Please identify and recommend
        promising stock and options trades I should consider. Research current market trends, unusual
        activity (especially from Unusual Whales), relevant news and discussions, and technical opportunities.

        For each recommendation, provide:
        - Whether it's a stock or options trade
        - The stock symbol/ticker
        - Price range estimates (for stocks) or strike price, expiration window, and position type (for options)
        - Your confidence level (0-100)
        - Clear reasoning for the recommendation

        Ensure recommendations are appropriately sized for a $#{normalized_liquidity_amount.round(2)} account.
      PROMPT

      if positions.any?
        prompt += "\n\nMy current positions:\n"
        positions.each do |position|
          prompt += format_position(position)
        end
        prompt += "\nPlease consider recommendations for managing, scaling, or closing these positions as appropriate."
      end

      prompt
    end

    def format_position(position)
      case position.type&.downcase
      when "stock"
        "- #{position.quantity} shares of #{position.symbol} (#{position.position_type})\n"
      when "option"
        strike = position.strike_price&.round(2)
        expiry = position.expiration_date
        "- #{position.quantity} contracts #{position.symbol} #{strike} #{position.option_type}, expiring #{expiry} (#{position.position_type})\n"
      else
        ""
      end
    end

    def extract_trades(payload)
      output = Array(payload["output"])
      function_call = output.reverse.find do |item|
        item["type"] == "function_call" && item["name"] == FUNCTION_NAME
      end

      raise Error, "xAI did not return #{FUNCTION_NAME}." if function_call.blank?

      arguments = JSON.parse(function_call.fetch("arguments"))
      trades_data = arguments["trades"]

      raise Error, "xAI returned invalid #{FUNCTION_NAME} arguments." unless trades_data.is_a?(Array)

      trades = trades_data.filter_map do |trade_data|
        next unless trade_data.is_a?(Hash)

        trade = build_trade(trade_data)
        next unless trade&.valid?

        trade
      end

      raise Error, "xAI returned no valid trade recommendations." if trades.empty?

      trades
    end

    def build_trade(data)
      Trade.new(
        type: data["type"]&.downcase,
        symbol: data["symbol"]&.upcase&.strip,
        min_price: Float(data["min_price"], exception: false) || 0,
        max_price: Float(data["max_price"], exception: false) || 0,
        confidence: Integer(data["confidence"], exception: false) || 0,
        reasoning: data["reasoning"]&.to_s&.strip,
        strike_price: Float(data["strike_price"], exception: false),
        expiration_date_min: data["expiration_date_min"],
        expiration_date_max: data["expiration_date_max"],
        option_type: data["option_type"]&.downcase,
        position_type: data["position_type"]&.downcase
      )
    end

    def failure(message)
      Result.new(trades: [], error_message: message)
    end
  end
end
