# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'tool list construction' do
  it 'exposes web_search, x_search, MCP-namespaced tools, and trade_recommendations on normal turns' do
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])

    build_service(xai_client: xai, max_iterations: 5).call

    tools = xai.calls.first[:tools]
    expect(tools.map { |t| t[:type] }).to include('x_search', 'web_search', 'function')
    function_names = tools.select { |t| t[:type] == 'function' }.map { |t| t[:name] }
    expect(function_names).to include(
      hellthread_tool_full_name,
      unusual_whales_tool_full_name,
      described_class::FUNCTION_NAME
    )
  end
end
