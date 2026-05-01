# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'iteration limit' do
  it 'fails when MAX_ITERATIONS elapses without a trade_recommendations call' do
    allow(hellthread_client).to receive(:call_tool).and_return(text_result('noise'))
    no_trade = { 'output' => [tool_call(name: hellthread_tool_full_name, call_id: 'ht_only')] }
    xai = FakeXaiClient.new([no_trade, no_trade, force_trade_response])

    result = build_service(xai_client: xai, max_iterations: 3).call

    expect(result).not_to be_success
    expect(result.error_message).to include('within 3 iterations')
    expect(result.iterations).to eq(3)
  end

  def force_trade_response
    { 'output' => [tool_call(name: hellthread_tool_full_name, call_id: 'late')] }
  end
end
