# frozen_string_literal: true

require_relative 'structs'

module Trading
  # Runs an isolated, context-free sentiment-analysis call to xAI for each pick.
  # Each call exposes only the built-in web_search and x_search tools and uses a
  # single user message — no system prompt, no prior loop history. The plain-text
  # response is captured per trade and surfaced to the listener so it can be
  # printed to stdout one pick at a time.
  class SentimentAnalyzer
    SENTIMENT_TOOLS = [{ type: 'web_search' }, { type: 'x_search' }].freeze
    TOOL_CHOICE = 'auto'

    def initialize(xai_client:, listener: nil, usage_accumulator: nil)
      @xai_client = xai_client
      @listener = listener
      @usage = usage_accumulator
    end

    def analyze(trades)
      Array(trades).map { |trade| analyze_one(trade) }
    end

    private

    def analyze_one(trade)
      notify(:sentiment_started, trade: trade)
      payload = post_for(trade)
      text = MessageTextExtractor.extract(payload['output'])
      analysis = SentimentAnalysis.new(trade: trade, text: text)
      notify(:sentiment_completed, trade: trade, sentiment: text)
      analysis
    end

    def post_for(trade)
      payload = @xai_client.post(input: input_for(trade), tools: SENTIMENT_TOOLS, tool_choice: TOOL_CHOICE)
      @usage&.add(payload['usage'])
      payload
    end

    def input_for(trade)
      [{ role: 'user', content: prompt_for(trade) }]
    end

    def prompt_for(trade)
      "Provide a straight-up sentiment analysis on #{trade.symbol}. " \
        'Use web search and X search as needed. ' \
        'Reply with a concise plain-text assessment of bullish vs. bearish sentiment, ' \
        'notable catalysts, and recent chatter. Do not ask clarifying questions.'
    end

    def notify(event, **payload)
      return unless @listener.respond_to?(event)

      @listener.public_send(event, **payload)
    end
  end

  # Pulls assistant-visible text out of an xAI Responses API output array.
  # Skips reasoning items and accumulates 'message' content blocks plus any
  # bare 'text' items the model may emit alongside built-in tool calls.
  module MessageTextExtractor
    module_function

    def extract(output_items)
      pieces = Array(output_items).flat_map { |item| pieces_for(item) }
      pieces.compact.reject(&:empty?).join("\n\n")
    end

    def pieces_for(item)
      return [] unless item.is_a?(Hash)

      case item['type']
      when 'message' then [text_from_content(item['content'])]
      when 'text' then [item['text'].to_s]
      else []
      end
    end

    def text_from_content(content)
      return content.to_s unless content.is_a?(Array)

      content.filter_map { |c| c.is_a?(Hash) ? c['text'] : c }.join("\n")
    end
  end
end
