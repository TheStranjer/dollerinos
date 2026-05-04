# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'tool list construction' do
  it 'hides trade_recommendations during the gather phase when quotas are unmet' do
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])

    build_service(xai_client: xai, max_iterations: 5).call

    tools = xai.calls.first[:tools]
    expect(tools.map { |t| t[:type] }).to include('x_search', 'web_search', 'function')
    function_names = tools.select { |t| t[:type] == 'function' }.map { |t| t[:name] }
    expect(function_names).to include(hellthread_tool_full_name, unusual_whales_tool_full_name)
    expect(function_names).not_to include(described_class::FUNCTION_NAME)
  end
end
