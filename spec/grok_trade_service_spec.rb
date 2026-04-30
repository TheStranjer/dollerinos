require_relative "../spec/spec_helper"
require_relative "../lib/grok_trade_service"

describe Trading::GrokTradeService do
  describe "Position struct" do
    it "has correct attributes" do
      position = described_class::Position.new(
        type: "stock",
        symbol: "AAPL",
        quantity: 100,
        position_type: "long"
      )
      expect(position.type).to eq("stock")
      expect(position.symbol).to eq("AAPL")
      expect(position.quantity).to eq(100)
      expect(position.position_type).to eq("long")
    end

    it "supports option positions with strike and expiration" do
      position = described_class::Position.new(
        type: "option",
        symbol: "TSLA",
        quantity: 5,
        position_type: "long",
        strike_price: 250.0,
        expiration_date: "2026-05-15",
        option_type: "call"
      )
      expect(position.type).to eq("option")
      expect(position.symbol).to eq("TSLA")
      expect(position.quantity).to eq(5)
      expect(position.strike_price).to eq(250.0)
      expect(position.expiration_date).to eq("2026-05-15")
      expect(position.option_type).to eq("call")
    end

    it "supports short positions" do
      position = described_class::Position.new(
        type: "stock",
        symbol: "SPY",
        quantity: 50,
        position_type: "short"
      )
      expect(position.position_type).to eq("short")
    end
  end

  describe "Trade struct" do
    describe "#valid?" do
      it "returns true for valid stock trade" do
        trade = described_class::Trade.new(
          type: "stock",
          symbol: "AAPL",
          min_price: 150.0,
          max_price: 160.0,
          confidence: 75,
          reasoning: "Strong fundamentals"
        )
        expect(trade).to be_valid
      end

      it "returns true for valid option trade" do
        trade = described_class::Trade.new(
          type: "option",
          symbol: "AAPL",
          min_price: 2.0,
          max_price: 5.0,
          confidence: 60,
          reasoning: "Bullish setup",
          strike_price: 155.0,
          expiration_date_min: "2026-05-15",
          expiration_date_max: "2026-05-22",
          option_type: "call",
          position_type: "buy"
        )
        expect(trade).to be_valid
      end

      it "returns false for invalid type" do
        trade = described_class::Trade.new(
          type: "futures",
          symbol: "AAPL",
          min_price: 150.0,
          max_price: 160.0,
          confidence: 75,
          reasoning: "Strong fundamentals"
        )
        expect(trade).not_to be_valid
      end

      it "returns false when symbol is blank" do
        trade = described_class::Trade.new(
          type: "stock",
          symbol: "",
          min_price: 150.0,
          max_price: 160.0,
          confidence: 75,
          reasoning: "Strong fundamentals"
        )
        expect(trade).not_to be_valid
      end

      it "returns false when min_price is zero or negative" do
        trade = described_class::Trade.new(
          type: "stock",
          symbol: "AAPL",
          min_price: 0,
          max_price: 160.0,
          confidence: 75,
          reasoning: "Strong fundamentals"
        )
        expect(trade).not_to be_valid
      end

      it "returns false when max_price is less than min_price" do
        trade = described_class::Trade.new(
          type: "stock",
          symbol: "AAPL",
          min_price: 160.0,
          max_price: 150.0,
          confidence: 75,
          reasoning: "Strong fundamentals"
        )
        expect(trade).not_to be_valid
      end

      it "returns false when confidence is out of range" do
        trade = described_class::Trade.new(
          type: "stock",
          symbol: "AAPL",
          min_price: 150.0,
          max_price: 160.0,
          confidence: 150,
          reasoning: "Strong fundamentals"
        )
        expect(trade).not_to be_valid
      end

      it "returns false when reasoning is blank" do
        trade = described_class::Trade.new(
          type: "stock",
          symbol: "AAPL",
          min_price: 150.0,
          max_price: 160.0,
          confidence: 75,
          reasoning: ""
        )
        expect(trade).not_to be_valid
      end
    end

    describe "#stock?" do
      it "returns true for stock trades" do
        trade = described_class::Trade.new(
          type: "stock",
          symbol: "AAPL",
          min_price: 150.0,
          max_price: 160.0,
          confidence: 75,
          reasoning: "Good"
        )
        expect(trade).to be_stock
      end

      it "returns false for option trades" do
        trade = described_class::Trade.new(
          type: "option",
          symbol: "AAPL",
          min_price: 2.0,
          max_price: 5.0,
          confidence: 75,
          reasoning: "Good"
        )
        expect(trade).not_to be_stock
      end
    end

    describe "#option?" do
      it "returns true for option trades" do
        trade = described_class::Trade.new(
          type: "option",
          symbol: "AAPL",
          min_price: 2.0,
          max_price: 5.0,
          confidence: 75,
          reasoning: "Good"
        )
        expect(trade).to be_option
      end

      it "returns false for stock trades" do
        trade = described_class::Trade.new(
          type: "stock",
          symbol: "AAPL",
          min_price: 150.0,
          max_price: 160.0,
          confidence: 75,
          reasoning: "Good"
        )
        expect(trade).not_to be_option
      end
    end
  end

  describe "Result struct" do
    describe "#success?" do
      it "returns true when error_message is blank" do
        result = described_class::Result.new(trades: [], error_message: nil)
        expect(result).to be_success
      end

      it "returns true when error_message is empty string" do
        result = described_class::Result.new(trades: [], error_message: "")
        expect(result).to be_success
      end

      it "returns false when error_message is present" do
        result = described_class::Result.new(trades: [], error_message: "Something went wrong")
        expect(result).not_to be_success
      end
    end
  end

  describe "#initialize" do
    it "stores liquidity_amount" do
      service = described_class.new(liquidity_amount: 5000)
      expect(service.instance_variable_get(:@liquidity_amount)).to eq(5000)
    end

    it "stores default time if not provided" do
      service = described_class.new(liquidity_amount: 5000)
      expect(service.instance_variable_get(:@now)).not_to be_nil
    end

    it "accepts custom time" do
      custom_time = Time.parse("2026-01-01 12:00:00")
      service = described_class.new(liquidity_amount: 5000, now: custom_time)
      expect(service.instance_variable_get(:@now)).to eq(custom_time)
    end

    it "stores empty positions by default" do
      service = described_class.new(liquidity_amount: 5000)
      expect(service.instance_variable_get(:@positions)).to eq([])
    end

    it "accepts positions argument and stores it" do
      positions = [
        described_class::Position.new(type: "stock", symbol: "AAPL", quantity: 100, position_type: "long")
      ]
      service = described_class.new(liquidity_amount: 5000, positions: positions)
      expect(service.instance_variable_get(:@positions)).to eq(positions)
    end

    it "converts positions to array if single position is passed" do
      position = described_class::Position.new(type: "stock", symbol: "AAPL", quantity: 100, position_type: "long")
      service = described_class.new(liquidity_amount: 5000, positions: position)
      expect(service.instance_variable_get(:@positions)).to be_an(Array)
      expect(service.instance_variable_get(:@positions).size).to eq(1)
    end

    it "loads API keys from environment variables" do
      allow(ENV).to receive(:[]).with("XAI_API_KEY").and_return("test_key")
      allow(ENV).to receive(:[]).with("HELLTHREAD_API_KEY").and_return("ht_key")
      allow(ENV).to receive(:[]).with("UNUSUAL_WHALES_API_KEY").and_return("uw_key")

      service = described_class.new(liquidity_amount: 5000)
      expect(service.instance_variable_get(:@xai_api_key)).to eq("test_key")
      expect(service.instance_variable_get(:@hellthread_api_key)).to eq("ht_key")
      expect(service.instance_variable_get(:@unusual_whales_api_key)).to eq("uw_key")
    end
  end

  describe "#call" do
    let(:service) do
      described_class.new(
        liquidity_amount: 5000,
        xai_api_key: "test_key",
        hellthread_api_key: "ht_key",
        unusual_whales_api_key: "uw_key"
      )
    end

    describe "validation" do
      it "fails if liquidity_amount is not a number" do
        bad_service = described_class.new(
          liquidity_amount: "not_a_number",
          xai_api_key: "test_key",
          hellthread_api_key: "ht_key",
          unusual_whales_api_key: "uw_key"
        )
        result = bad_service.call
        expect(result).not_to be_success
        expect(result.error_message).to include("positive number")
      end

      it "fails if liquidity_amount is zero" do
        bad_service = described_class.new(
          liquidity_amount: 0,
          xai_api_key: "test_key",
          hellthread_api_key: "ht_key",
          unusual_whales_api_key: "uw_key"
        )
        result = bad_service.call
        expect(result).not_to be_success
        expect(result.error_message).to include("positive number")
      end

      it "fails if liquidity_amount is negative" do
        bad_service = described_class.new(
          liquidity_amount: -1000,
          xai_api_key: "test_key",
          hellthread_api_key: "ht_key",
          unusual_whales_api_key: "uw_key"
        )
        result = bad_service.call
        expect(result).not_to be_success
        expect(result.error_message).to include("positive number")
      end

      it "fails if XAI_API_KEY is missing" do
        bad_service = described_class.new(
          liquidity_amount: 5000,
          xai_api_key: nil,
          hellthread_api_key: "ht_key",
          unusual_whales_api_key: "uw_key"
        )
        result = bad_service.call
        expect(result).not_to be_success
        expect(result.error_message).to include("XAI_API_KEY")
      end

      it "fails if HELLTHREAD_API_KEY is missing" do
        bad_service = described_class.new(
          liquidity_amount: 5000,
          xai_api_key: "test_key",
          hellthread_api_key: nil,
          unusual_whales_api_key: "uw_key"
        )
        result = bad_service.call
        expect(result).not_to be_success
        expect(result.error_message).to include("HELLTHREAD_API_KEY")
      end

      it "fails if UNUSUAL_WHALES_API_KEY is missing" do
        bad_service = described_class.new(
          liquidity_amount: 5000,
          xai_api_key: "test_key",
          hellthread_api_key: "ht_key",
          unusual_whales_api_key: nil
        )
        result = bad_service.call
        expect(result).not_to be_success
        expect(result.error_message).to include("UNUSUAL_WHALES_API_KEY")
      end
    end

    describe "successful response handling" do
      let(:valid_payload) do
        {
          "output" => [
            {
              "type" => "function_call",
              "name" => "trade_recommendations",
              "arguments" => JSON.generate({
                "trades" => [
                  {
                    "type" => "stock",
                    "symbol" => "AAPL",
                    "min_price" => 150.0,
                    "max_price" => 160.0,
                    "confidence" => 75,
                    "reasoning" => "Strong earnings"
                  },
                  {
                    "type" => "option",
                    "symbol" => "TSLA",
                    "min_price" => 3.0,
                    "max_price" => 7.0,
                    "confidence" => 60,
                    "reasoning" => "Bullish momentum",
                    "strike_price" => 250.0,
                    "expiration_date_min" => "2026-05-15",
                    "expiration_date_max" => "2026-05-22",
                    "option_type" => "call",
                    "position_type" => "buy"
                  }
                ]
              })
            }
          ]
        }
      end

      before do
        allow(service).to receive(:fetch_payload).and_return(valid_payload)
      end

      it "returns successful result with trades" do
        result = service.call
        expect(result).to be_success
        expect(result.trades.size).to eq(2)
      end

      it "extracts stock trades correctly" do
        result = service.call
        stock = result.trades.find(&:stock?)
        expect(stock.symbol).to eq("AAPL")
        expect(stock.min_price).to eq(150.0)
        expect(stock.max_price).to eq(160.0)
        expect(stock.confidence).to eq(75)
        expect(stock.reasoning).to eq("Strong earnings")
      end

      it "extracts option trades correctly" do
        result = service.call
        option = result.trades.find(&:option?)
        expect(option.symbol).to eq("TSLA")
        expect(option.min_price).to eq(3.0)
        expect(option.max_price).to eq(7.0)
        expect(option.confidence).to eq(60)
        expect(option.reasoning).to eq("Bullish momentum")
        expect(option.strike_price).to eq(250.0)
        expect(option.expiration_date_min).to eq("2026-05-15")
        expect(option.expiration_date_max).to eq("2026-05-22")
        expect(option.option_type).to eq("call")
        expect(option.position_type).to eq("buy")
      end

      it "normalizes symbol to uppercase" do
        payload = {
          "output" => [
            {
              "type" => "function_call",
              "name" => "trade_recommendations",
              "arguments" => JSON.generate({
                "trades" => [
                  {
                    "type" => "stock",
                    "symbol" => "aapl",
                    "min_price" => 150.0,
                    "max_price" => 160.0,
                    "confidence" => 75,
                    "reasoning" => "Good"
                  }
                ]
              })
            }
          ]
        }
        allow(service).to receive(:fetch_payload).and_return(payload)

        result = service.call
        expect(result.trades.first.symbol).to eq("AAPL")
      end

      it "normalizes type to lowercase" do
        payload = {
          "output" => [
            {
              "type" => "function_call",
              "name" => "trade_recommendations",
              "arguments" => JSON.generate({
                "trades" => [
                  {
                    "type" => "STOCK",
                    "symbol" => "AAPL",
                    "min_price" => 150.0,
                    "max_price" => 160.0,
                    "confidence" => 75,
                    "reasoning" => "Good"
                  }
                ]
              })
            }
          ]
        }
        allow(service).to receive(:fetch_payload).and_return(payload)

        result = service.call
        expect(result.trades.first.type).to eq("stock")
      end

      it "filters out invalid trades" do
        payload = {
          "output" => [
            {
              "type" => "function_call",
              "name" => "trade_recommendations",
              "arguments" => JSON.generate({
                "trades" => [
                  {
                    "type" => "stock",
                    "symbol" => "AAPL",
                    "min_price" => 150.0,
                    "max_price" => 160.0,
                    "confidence" => 75,
                    "reasoning" => "Good"
                  },
                  {
                    "type" => "stock",
                    "symbol" => "",
                    "min_price" => 100.0,
                    "max_price" => 110.0,
                    "confidence" => 50,
                    "reasoning" => "Bad symbol"
                  },
                  {
                    "type" => "stock",
                    "symbol" => "TSLA",
                    "min_price" => 200.0,
                    "max_price" => 190.0,
                    "confidence" => 60,
                    "reasoning" => "Invalid range"
                  }
                ]
              })
            }
          ]
        }
        allow(service).to receive(:fetch_payload).and_return(payload)

        result = service.call
        expect(result.trades.size).to eq(1)
        expect(result.trades.first.symbol).to eq("AAPL")
      end
    end

    describe "error handling" do
      it "returns error when function_call is not found" do
        payload = { "output" => [{ "type" => "text", "content" => "No function call" }] }
        allow(service).to receive(:fetch_payload).and_return(payload)

        result = service.call
        expect(result).not_to be_success
        expect(result.error_message).to include("did not return")
      end

      it "returns error when trades argument is missing" do
        payload = {
          "output" => [
            {
              "type" => "function_call",
              "name" => "trade_recommendations",
              "arguments" => JSON.generate({})
            }
          ]
        }
        allow(service).to receive(:fetch_payload).and_return(payload)

        result = service.call
        expect(result).not_to be_success
      end

      it "returns error when trades is not an array" do
        payload = {
          "output" => [
            {
              "type" => "function_call",
              "name" => "trade_recommendations",
              "arguments" => JSON.generate({ "trades" => "not an array" })
            }
          ]
        }
        allow(service).to receive(:fetch_payload).and_return(payload)

        result = service.call
        expect(result).not_to be_success
        expect(result.error_message).to include("invalid")
      end

      it "returns error when no valid trades are returned" do
        payload = {
          "output" => [
            {
              "type" => "function_call",
              "name" => "trade_recommendations",
              "arguments" => JSON.generate({
                "trades" => [
                  {
                    "type" => "invalid",
                    "symbol" => "",
                    "min_price" => -100.0,
                    "max_price" => 0,
                    "confidence" => 150,
                    "reasoning" => ""
                  }
                ]
              })
            }
          ]
        }
        allow(service).to receive(:fetch_payload).and_return(payload)

        result = service.call
        expect(result).not_to be_success
        expect(result.error_message).to include("no valid")
      end

      it "returns error on JSON parsing error" do
        allow(service).to receive(:fetch_payload).and_raise(JSON::ParserError.new("Invalid JSON"))

        result = service.call
        expect(result).not_to be_success
        expect(result.error_message).to include("invalid JSON")
      end

      it "returns error on standard error" do
        allow(service).to receive(:fetch_payload).and_raise(StandardError.new("Network error"))

        result = service.call
        expect(result).not_to be_success
        expect(result.error_message).to include("failed")
      end
    end
  end

  describe "request_body" do
    let(:service) do
      described_class.new(
        liquidity_amount: 5000,
        xai_api_key: "test_key",
        hellthread_api_key: "ht_key",
        unusual_whales_api_key: "uw_key"
      )
    end

    it "includes correct model name" do
      body = service.send(:request_body)
      expect(body[:model]).to eq("grok-4.20-reasoning")
    end

    it "includes system and user prompts" do
      body = service.send(:request_body)
      expect(body[:input].size).to eq(2)
      expect(body[:input][0][:role]).to eq("system")
      expect(body[:input][1][:role]).to eq("user")
    end

    it "includes all required tools" do
      body = service.send(:request_body)
      tools = body[:tools]

      tool_types = tools.map { |t| t[:type] }
      expect(tool_types).to include("x_search", "web_search", "mcp", "function")

      mcp_servers = tools.select { |t| t[:type] == "mcp" }.map { |t| t[:server_label] }
      expect(mcp_servers).to include("hellthread", "unusual-whales")
    end

    it "includes trade_recommendations function with correct schema" do
      body = service.send(:request_body)
      function = body[:tools].find { |t| t[:type] == "function" && t[:name] == "trade_recommendations" }

      expect(function).not_to be_nil
      expect(function[:parameters][:properties][:trades][:items][:properties]).to have_key(:type)
      expect(function[:parameters][:properties][:trades][:items][:properties]).to have_key(:symbol)
      expect(function[:parameters][:properties][:trades][:items][:properties]).to have_key(:confidence)
    end

    it "includes liquidity amount in user prompt" do
      body = service.send(:request_body)
      user_prompt = body[:input][1][:content]
      expect(user_prompt).to include("5000")
    end
  end

  describe "user_prompt" do
    let(:service) do
      described_class.new(
        liquidity_amount: 10000,
        xai_api_key: "test_key",
        hellthread_api_key: "ht_key",
        unusual_whales_api_key: "uw_key"
      )
    end

    it "includes the liquidity amount" do
      prompt = service.send(:user_prompt)
      expect(prompt).to include("10000")
    end

    it "mentions stocks and options" do
      prompt = service.send(:user_prompt)
      expect(prompt.downcase).to include("stock")
      expect(prompt.downcase).to include("option")
    end

    it "mentions market research" do
      prompt = service.send(:user_prompt)
      expect(prompt.downcase).to include("trend")
    end

    it "does not include position section when no positions" do
      prompt = service.send(:user_prompt)
      expect(prompt).not_to include("current positions")
    end

    it "includes position section when stock positions are provided" do
      positions = [
        described_class::Position.new(type: "stock", symbol: "AAPL", quantity: 100, position_type: "long")
      ]
      service_with_positions = described_class.new(
        liquidity_amount: 10000,
        positions: positions,
        xai_api_key: "test_key",
        hellthread_api_key: "ht_key",
        unusual_whales_api_key: "uw_key"
      )
      prompt = service_with_positions.send(:user_prompt)
      expect(prompt).to include("current positions")
      expect(prompt).to include("100 shares of AAPL")
      expect(prompt).to include("long")
    end

    it "includes position section when option positions are provided" do
      positions = [
        described_class::Position.new(
          type: "option",
          symbol: "TSLA",
          quantity: 5,
          position_type: "long",
          strike_price: 250.0,
          expiration_date: "2026-05-15",
          option_type: "call"
        )
      ]
      service_with_positions = described_class.new(
        liquidity_amount: 10000,
        positions: positions,
        xai_api_key: "test_key",
        hellthread_api_key: "ht_key",
        unusual_whales_api_key: "uw_key"
      )
      prompt = service_with_positions.send(:user_prompt)
      expect(prompt).to include("current positions")
      expect(prompt).to include("5 contracts TSLA")
      expect(prompt).to include("250.0")
      expect(prompt).to include("2026-05-15")
      expect(prompt).to include("long")
      expect(prompt).to include("call")
    end

    it "includes multiple positions in prompt" do
      positions = [
        described_class::Position.new(type: "stock", symbol: "AAPL", quantity: 100, position_type: "long"),
        described_class::Position.new(type: "stock", symbol: "SPY", quantity: 50, position_type: "short")
      ]
      service_with_positions = described_class.new(
        liquidity_amount: 10000,
        positions: positions,
        xai_api_key: "test_key",
        hellthread_api_key: "ht_key",
        unusual_whales_api_key: "uw_key"
      )
      prompt = service_with_positions.send(:user_prompt)
      expect(prompt).to include("100 shares of AAPL")
      expect(prompt).to include("50 shares of SPY")
      expect(prompt).to include("short")
    end
  end

  describe "normalized_liquidity_amount" do
    it "converts string to float" do
      service = described_class.new(
        liquidity_amount: "5000",
        xai_api_key: "test_key",
        hellthread_api_key: "ht_key",
        unusual_whales_api_key: "uw_key"
      )
      expect(service.send(:normalized_liquidity_amount)).to eq(5000.0)
    end

    it "handles float inputs" do
      service = described_class.new(
        liquidity_amount: 5000.50,
        xai_api_key: "test_key",
        hellthread_api_key: "ht_key",
        unusual_whales_api_key: "uw_key"
      )
      expect(service.send(:normalized_liquidity_amount)).to eq(5000.50)
    end

    it "returns nil for non-numeric input" do
      service = described_class.new(
        liquidity_amount: "not a number",
        xai_api_key: "test_key",
        hellthread_api_key: "ht_key",
        unusual_whales_api_key: "uw_key"
      )
      expect(service.send(:normalized_liquidity_amount)).to be_nil
    end

    it "returns nil for negative numbers" do
      service = described_class.new(
        liquidity_amount: -1000,
        xai_api_key: "test_key",
        hellthread_api_key: "ht_key",
        unusual_whales_api_key: "uw_key"
      )
      expect(service.send(:normalized_liquidity_amount)).to be_nil
    end

    it "returns nil for zero" do
      service = described_class.new(
        liquidity_amount: 0,
        xai_api_key: "test_key",
        hellthread_api_key: "ht_key",
        unusual_whales_api_key: "uw_key"
      )
      expect(service.send(:normalized_liquidity_amount)).to be_nil
    end
  end

  describe "build_trade" do
    let(:service) do
      described_class.new(
        liquidity_amount: 5000,
        xai_api_key: "test_key",
        hellthread_api_key: "ht_key",
        unusual_whales_api_key: "uw_key"
      )
    end

    it "builds trade from hash with all fields" do
      data = {
        "type" => "stock",
        "symbol" => "AAPL",
        "min_price" => 150.0,
        "max_price" => 160.0,
        "confidence" => 75,
        "reasoning" => "Good fundamentals"
      }

      trade = service.send(:build_trade, data)

      expect(trade.type).to eq("stock")
      expect(trade.symbol).to eq("AAPL")
      expect(trade.min_price).to eq(150.0)
      expect(trade.max_price).to eq(160.0)
      expect(trade.confidence).to eq(75)
      expect(trade.reasoning).to eq("Good fundamentals")
    end

    it "handles missing optional fields for stocks" do
      data = {
        "type" => "stock",
        "symbol" => "AAPL",
        "min_price" => 150.0,
        "max_price" => 160.0,
        "confidence" => 75,
        "reasoning" => "Good"
      }

      trade = service.send(:build_trade, data)

      expect(trade.strike_price).to be_nil
      expect(trade.option_type).to be_nil
      expect(trade.position_type).to be_nil
    end

    it "builds option trade with all fields" do
      data = {
        "type" => "option",
        "symbol" => "TSLA",
        "min_price" => 3.0,
        "max_price" => 7.0,
        "confidence" => 60,
        "reasoning" => "Bullish",
        "strike_price" => 250.0,
        "expiration_date_min" => "2026-05-15",
        "expiration_date_max" => "2026-05-22",
        "option_type" => "call",
        "position_type" => "buy"
      }

      trade = service.send(:build_trade, data)

      expect(trade.option?).to be true
      expect(trade.strike_price).to eq(250.0)
      expect(trade.expiration_date_min).to eq("2026-05-15")
      expect(trade.expiration_date_max).to eq("2026-05-22")
      expect(trade.option_type).to eq("call")
      expect(trade.position_type).to eq("buy")
    end

    it "handles missing price fields gracefully" do
      data = {
        "type" => "stock",
        "symbol" => "AAPL",
        "confidence" => 75,
        "reasoning" => "Good"
      }

      trade = service.send(:build_trade, data)

      expect(trade.min_price).to eq(0)
      expect(trade.max_price).to eq(0)
    end

    it "handles missing confidence field" do
      data = {
        "type" => "stock",
        "symbol" => "AAPL",
        "min_price" => 150.0,
        "max_price" => 160.0,
        "reasoning" => "Good"
      }

      trade = service.send(:build_trade, data)

      expect(trade.confidence).to eq(0)
    end
  end
end
