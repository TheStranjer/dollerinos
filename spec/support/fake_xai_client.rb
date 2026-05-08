# frozen_string_literal: true

require 'json'

# A scripted xAI client double: each call returns the next payload from the
# queue and records the input/tools/tool_choice for later inspection. When the
# queue is exhausted, the fake auto-extends with a context-appropriate payload
# (sentiment text for sentiment-shaped calls, a stub trade_recommendations
# call otherwise) so every spec that scripts only the initial loop still runs
# the new sentiment + reconsideration phases without explicit padding.
class FakeXaiClient
  AUTO_SENTIMENT_TEXT = 'auto-extended sentiment placeholder'
  AUTO_TRADE = {
    'type' => 'stock', 'symbol' => 'AAPL', 'min_price' => 150.0, 'max_price' => 160.0,
    'confidence' => 75, 'reasoning' => 'auto-extended trade placeholder', 'position_type' => 'buy'
  }.freeze

  attr_reader :calls

  def initialize(payloads, auto_extend: true)
    @payloads = payloads.dup
    @calls = []
    @auto_extend = auto_extend
  end

  def post(input:, tools:, tool_choice:)
    @calls << { input: deep_dup(input), tools: tools, tool_choice: tool_choice }
    return @payloads.shift unless @payloads.empty?

    raise 'FakeXaiClient ran out of scripted payloads' unless @auto_extend

    auto_extended_payload(input, tools, tool_choice)
  end

  def factory
    lambda { |api_key:, har_archiver:|
      _ = api_key
      _ = har_archiver
      self
    }
  end

  private

  def deep_dup(items)
    items.map { |item| item.is_a?(Hash) ? item.dup : item }
  end

  def auto_extended_payload(input, tools, tool_choice)
    return sentiment_payload if sentiment_call?(input, tools, tool_choice)

    trade_payload
  end

  def sentiment_call?(input, tools, _tool_choice)
    input.length == 1 && input.first[:role] == 'user' &&
      tools.length == 2 && tools.map { |t| t[:type] || t['type'] }.sort == %w[web_search x_search]
  end

  def sentiment_payload
    {
      'output' => [
        { 'type' => 'message', 'role' => 'assistant',
          'content' => [{ 'type' => 'text', 'text' => AUTO_SENTIMENT_TEXT }] }
      ]
    }
  end

  def trade_payload
    {
      'output' => [{
        'type' => 'function_call', 'id' => 'fc_auto', 'call_id' => 'auto',
        'name' => 'trade_recommendations',
        'arguments' => JSON.generate({ 'trades' => [AUTO_TRADE] })
      }]
    }
  end
end
