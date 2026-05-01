# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'system prompt iteration tracking' do
  it 'includes iteration progress in the system message each turn' do
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])

    build_service(xai_client: xai, max_iterations: 7).call

    expect(xai.calls.first[:input].first[:content]).to include('iteration 1/7')
  end

  it 'marks the final iteration with a forcing directive' do
    allow(hellthread_client).to receive(:call_tool).and_return(text_result('noise'))
    xai = FakeXaiClient.new([
                              { 'output' => [tool_call(name: hellthread_tool_full_name, call_id: 'ht')] },
                              { 'output' => [trade_call(trades: [valid_trade])] }
                            ])

    build_service(xai_client: xai, max_iterations: 2).call

    final_system = xai.calls[1][:input].first[:content]
    expect(final_system).to include('FINAL iteration')
    expect(final_system).to include('iteration 2/2')
  end
end
