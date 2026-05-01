# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'on_iteration callback' do
  it 'invokes the callback for every turn with iteration metadata' do
    events = []
    allow(hellthread_client).to receive(:call_tool).and_return(text_result('ok'))
    xai = FakeXaiClient.new([
                              { 'output' => [tool_call(name: hellthread_tool_full_name, call_id: 'ht_1')] },
                              { 'output' => [trade_call(trades: [valid_trade])] }
                            ])

    build_service(xai_client: xai, on_iteration: ->(payload) { events << payload }).call

    expect(events.size).to eq(2)
    expect(events[0]).to include(iteration: 1, max_iterations: described_class::MAX_ITERATIONS)
    expect(events[0][:tool_results].first).to include(name: a_string_starting_with(described_class::HELLTHREAD_LABEL))
    expect(events[1]).to include(iteration: 2, tool_results: [])
  end
end
