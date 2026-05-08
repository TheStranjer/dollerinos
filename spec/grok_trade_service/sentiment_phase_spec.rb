# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

module SentimentPhaseHelpers
  def text_payload(text)
    { 'output' => [{ 'type' => 'message', 'role' => 'assistant',
                     'content' => [{ 'type' => 'text', 'text' => text }] }] }
  end

  def option_trade_data
    {
      'type' => 'option', 'symbol' => 'TSLA', 'min_price' => 3, 'max_price' => 7,
      'confidence' => 60, 'reasoning' => 'bullish', 'option_type' => 'call',
      'position_type' => 'buy', 'strike_price' => 250.0,
      'expiration_date_min' => '2026-05-15', 'expiration_date_max' => '2026-05-22'
    }
  end

  def find_sentiment_call(xai)
    xai.calls.find do |c|
      c[:tools].length == 2 &&
        c[:tools].map { |t| t[:type] || t['type'] }.sort == %w[web_search x_search]
    end
  end

  def two_pick_payloads
    [
      { 'output' => [trade_call(trades: [valid_trade, option_trade_data])] },
      text_payload('AAPL bullish'),
      text_payload('TSLA mixed'),
      { 'output' => [trade_call(trades: [valid_trade], call_id: 'final')] }
    ]
  end

  def one_pick_payloads(sentiment_text: 'AAPL bullish', final_trade: valid_trade)
    [
      { 'output' => [trade_call(trades: [valid_trade])] },
      text_payload(sentiment_text),
      { 'output' => [trade_call(trades: [final_trade], call_id: 'final')] }
    ]
  end
end

RSpec.configure { |c| c.include SentimentPhaseHelpers }

describe Trading::GrokTradeService, 'sentiment call shape' do
  it 'runs one sentiment call per pick after the initial loop concludes' do
    xai = FakeXaiClient.new(two_pick_payloads, auto_extend: false)

    build_service(xai_client: xai).call

    sentiment_calls = xai.calls.select do |c|
      c[:tools].length == 2 && c[:tools].map { |t| t[:type] || t['type'] }.sort == %w[web_search x_search]
    end
    expect(sentiment_calls.size).to eq(2)
  end

  it 'sends a context-free user message to each sentiment call' do
    xai = FakeXaiClient.new(one_pick_payloads, auto_extend: false)

    build_service(xai_client: xai).call

    sentiment_call = find_sentiment_call(xai)
    expect(sentiment_call[:input].size).to eq(1)
    expect(sentiment_call[:input].first[:role]).to eq('user')
    expect(sentiment_call[:input].first[:content]).to include('AAPL')
    expect(sentiment_call[:input].first[:content]).not_to include('liquidity')
    expect(sentiment_call[:input].first[:content]).not_to include('trade_recommendations')
  end
end

describe Trading::GrokTradeService, 'reconsideration tool exposure' do
  it 'opens reconsideration with full tool exposure and a fresh iteration budget' do
    xai = FakeXaiClient.new(one_pick_payloads, auto_extend: false)

    build_service(xai_client: xai, max_iterations: 5).call

    reconsider_call = xai.calls.last
    types = reconsider_call[:tools].map { |t| t[:type] || t['type'] }.compact
    names = reconsider_call[:tools].map { |t| t[:name] || t['name'] }.compact
    expect(types).to include('web_search', 'x_search')
    expect(names).to include(described_class::FUNCTION_NAME)
    expect(reconsider_call[:tool_choice]).to eq('auto')
  end
end

describe Trading::GrokTradeService, 'reconsideration preamble' do
  it 'prepends an "are you sure?" preamble to the reconsideration loop input' do
    xai = FakeXaiClient.new(one_pick_payloads(sentiment_text: 'AAPL bullish narrative'), auto_extend: false)

    build_service(xai_client: xai).call

    reconsider_input = xai.calls.last[:input]
    user_messages = reconsider_input.select { |i| (i[:role] || i['role']) == 'user' }
    preamble = user_messages.last[:content] || user_messages.last['content']
    expect(preamble).to include('RECONSIDERATION')
    expect(preamble).to include('Are you sure')
    expect(preamble).to include('AAPL bullish narrative')
    expect(preamble).to include('trade_recommendations')
  end
end

describe Trading::GrokTradeService, 'final result composition' do
  it 'returns the reconsideration loop trades as the final result' do
    final_trade = valid_trade.merge('symbol' => 'NVDA', 'reasoning' => 'final pick after sentiment')
    xai = FakeXaiClient.new(one_pick_payloads(final_trade: final_trade), auto_extend: false)

    result = build_service(xai_client: xai).call

    expect(result).to be_success
    expect(result.trades.map(&:symbol)).to eq(['NVDA'])
    expect(result.sentiment_analyses.map(&:trade).map(&:symbol)).to eq(['AAPL'])
    expect(result.sentiment_analyses.map(&:text)).to eq(['AAPL bullish'])
    expect(result.reconsideration_iterations).to eq(1)
  end
end

describe Trading::GrokTradeService, 'reconsideration follow-up research' do
  it 'allows the reconsideration loop to do additional research before finalizing' do
    allow(hellthread_client).to receive(:call_tool).and_return(text_result('reconsider chatter'))
    research_call = tool_call(name: hellthread_tool_full_name, call_id: 'rh_1')
    payloads = [
      { 'output' => [trade_call(trades: [valid_trade])] },
      text_payload('AAPL bullish'),
      { 'output' => [research_call] },
      { 'output' => [trade_call(trades: [valid_trade], call_id: 'final')] }
    ]
    xai = FakeXaiClient.new(payloads, auto_extend: false)

    result = build_service(xai_client: xai).call

    expect(result).to be_success
    expect(result.reconsideration_iterations).to eq(2)
  end
end

describe Trading::GrokTradeService, 'sentiment listener events' do
  let(:listener) do
    Class.new do
      attr_reader :events

      def initialize = @events = []
      Trading::IterationListener::EVENTS.each do |event|
        define_method(event) { |**payload| @events << { event: event, **payload } }
      end
    end.new
  end

  it 'fires sentiment_started/completed for each pick and reconsideration events for the second loop' do
    xai = FakeXaiClient.new(one_pick_payloads, auto_extend: false)

    build_service(xai_client: xai, on_iteration: listener).call

    types = listener.events.map { |e| e[:event] }
    expect(types).to include(:sentiment_started, :sentiment_completed, :reconsideration_started)
    expect(types).to include(:reconsideration_iteration_started, :reconsideration_iteration_finished)
  end

  it 'separates initial-loop iteration_finished from reconsideration_iteration_finished' do
    xai = FakeXaiClient.new(one_pick_payloads, auto_extend: false)

    build_service(xai_client: xai, on_iteration: listener).call

    initial_finished = listener.events.count { |e| e[:event] == :iteration_finished }
    reconsider_finished = listener.events.count { |e| e[:event] == :reconsideration_iteration_finished }
    expect(initial_finished).to eq(1)
    expect(reconsider_finished).to eq(1)
  end
end
