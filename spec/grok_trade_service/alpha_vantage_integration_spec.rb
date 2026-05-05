# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'Alpha Vantage validation' do
  it 'fails validation when ALPHA_VANTAGE key is missing' do
    expect(build_service(alpha_vantage_api_key: nil).call.error_message).to include('ALPHA_VANTAGE_API_KEY')
  end
end

describe Trading::GrokTradeService, 'Alpha Vantage MCP listing' do
  it 'lists tools from the alpha-vantage MCP server' do
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])

    build_service(xai_client: xai).call

    expect(alpha_vantage_client).to have_received(:tools)
  end
end

describe Trading::GrokTradeService, 'Alpha Vantage tool dispatch' do
  it 'dispatches alpha-vantage namespaced tool calls to the alpha-vantage client' do
    allow(alpha_vantage_client).to receive(:call_tool).and_return(text_result('AV result'))
    xai = FakeXaiClient.new([
                              { 'output' => [tool_call(name: alpha_vantage_tool_full_name, call_id: 'av')] },
                              { 'output' => [trade_call(trades: [valid_trade])] }
                            ])

    build_service(xai_client: xai, max_iterations: 3).call

    expect(alpha_vantage_client).to have_received(:call_tool).with(tool: alpha_vantage_tool, arguments: {})
  end
end

describe Trading::GrokTradeService, 'Alpha Vantage tool exposure' do
  it 'exposes alpha-vantage tools to xAI in the gather phase' do
    allow(alpha_vantage_client).to receive(:call_tool).and_return(text_result('AV'))
    xai = FakeXaiClient.new([
                              { 'output' => [tool_call(name: alpha_vantage_tool_full_name, call_id: 'av')] },
                              { 'output' => [trade_call(trades: [valid_trade])] }
                            ])

    build_service(xai_client: xai, max_iterations: 3).call

    tool_names = xai.calls.first[:tools].map { |t| t[:name] || t[:type] }
    expect(tool_names).to include(alpha_vantage_tool_full_name)
  end

  it 'mentions Alpha Vantage in the system prompt' do
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])

    build_service(xai_client: xai).call

    expect(xai.calls.first[:input].first[:content]).to include('Alpha Vantage', 'alpha-vantage__*')
  end
end
