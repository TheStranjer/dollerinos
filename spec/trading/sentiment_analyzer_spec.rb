# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

module SentimentAnalyzerHelpers
  def stock_trade(symbol: 'AAPL')
    Trading::Trade.new(
      type: 'stock', symbol: symbol, min_price: 150, max_price: 160,
      confidence: 75, reasoning: 'thesis', position_type: 'buy'
    )
  end

  def option_trade(symbol: 'TSLA')
    Trading::Trade.new(
      type: 'option', symbol: symbol, min_price: 3, max_price: 7,
      confidence: 60, reasoning: 'bullish', strike_price: 250.0,
      expiration_date_min: '2026-05-15', expiration_date_max: '2026-05-22',
      option_type: 'call', position_type: 'buy'
    )
  end

  def text_payload(text)
    { 'output' => [{ 'type' => 'message', 'role' => 'assistant',
                     'content' => [{ 'type' => 'text', 'text' => text }] }] }
  end
end

RSpec.configure { |c| c.include SentimentAnalyzerHelpers }

describe Trading::SentimentAnalyzer, 'tool exposure' do
  it 'makes one call per trade and exposes only web_search and x_search' do
    xai = FakeXaiClient.new([text_payload('AAPL bullish'), text_payload('TSLA mixed')], auto_extend: false)
    described_class.new(xai_client: xai).analyze([stock_trade, option_trade])

    expect(xai.calls.size).to eq(2)
    xai.calls.each do |call|
      expect(call[:tools].map { |t| t[:type] || t['type'] }.sort).to eq(%w[web_search x_search])
      expect(call[:tool_choice]).to eq('auto')
    end
  end
end

describe Trading::SentimentAnalyzer, 'context isolation' do
  it 'sends only a single user message — no system prompt and no prior history' do
    xai = FakeXaiClient.new([text_payload('AAPL bullish')], auto_extend: false)
    described_class.new(xai_client: xai).analyze([stock_trade])

    input = xai.calls.first[:input]
    expect(input.size).to eq(1)
    expect(input.first[:role]).to eq('user')
    expect(input.first[:content]).to include('AAPL')
    expect(input.first[:content]).not_to include('liquidity')
    expect(input.first[:content]).not_to include('trade_recommendations')
  end
end

describe Trading::SentimentAnalyzer, 'returned analyses' do
  it 'returns SentimentAnalysis structs in trade order with extracted text' do
    xai = FakeXaiClient.new(
      [text_payload('AAPL bullish — solid earnings'), text_payload('TSLA chatter is mixed')],
      auto_extend: false
    )
    analyses = described_class.new(xai_client: xai).analyze([stock_trade, option_trade])

    expect(analyses.map(&:trade).map(&:symbol)).to eq(%w[AAPL TSLA])
    expect(analyses.first.text).to include('AAPL bullish')
    expect(analyses.last.text).to include('TSLA chatter')
  end
end

describe Trading::SentimentAnalyzer, 'listener notifications' do
  let(:listener) do
    Class.new do
      attr_reader :events

      def initialize = @events = []
      def sentiment_started(**payload) = @events << [:started, payload[:trade].symbol]
      def sentiment_completed(**payload) = @events << [:completed, payload[:trade].symbol, payload[:sentiment]]
    end.new
  end

  it 'fires sentiment_started before sentiment_completed for each trade' do
    xai = FakeXaiClient.new([text_payload('TSLA mixed')], auto_extend: false)
    described_class.new(xai_client: xai, listener: listener).analyze([option_trade])

    expect(listener.events.first).to eq([:started, 'TSLA'])
    expect(listener.events.last).to eq([:completed, 'TSLA', 'TSLA mixed'])
  end
end

describe Trading::SentimentAnalyzer, 'usage accumulation' do
  it 'forwards each call usage into the supplied accumulator' do
    accumulator = Trading::UsageAccumulator.new
    payload_one = text_payload('A').merge('usage' => { 'input_tokens' => 10, 'output_tokens' => 5 })
    payload_two = text_payload('B').merge('usage' => { 'input_tokens' => 7, 'output_tokens' => 3 })
    xai = FakeXaiClient.new([payload_one, payload_two], auto_extend: false)

    described_class.new(xai_client: xai, usage_accumulator: accumulator).analyze([stock_trade, option_trade])

    expect(accumulator.to_h).to include('input_tokens' => 17, 'output_tokens' => 8)
  end
end
