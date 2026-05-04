# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

module PhasedToolsHelpers
  def types(tools)
    tools.map { |t| t[:type] }
  end

  def function_names(tools)
    tools.select { |t| t[:type] == 'function' }.map { |t| t[:name] }
  end
end

RSpec.configure { |c| c.include PhasedToolsHelpers }

describe Trading::GrokTradeService, 'gather phase iterations' do
  it 'hides trade_recommendations and met categories while quotas remain' do
    allow(hellthread_client).to receive(:call_tool).and_return(text_result('biz'))
    payloads = [
      { 'output' => Array.new(5) { |i| web_search_output(call_id: "ws_#{i}") } },
      { 'output' => [trade_call(trades: [valid_trade])] }
    ]
    xai = FakeXaiClient.new(payloads)

    build_service(xai_client: xai, max_iterations: 10).call

    second_tools = xai.calls[1][:tools]
    expect(types(second_tools)).not_to include('web_search')
    expect(function_names(second_tools)).not_to include(described_class::FUNCTION_NAME)
  end
end

describe Trading::GrokTradeService, 'open phase iteration' do
  it 'exposes every research tool and trade_recommendations once all quotas are met' do
    allow(hellthread_client).to receive(:call_tool).and_return(text_result('biz'))
    allow(unusual_whales_client).to receive(:call_tool).and_return(text_result('uw'))
    payloads = [
      { 'output' => Array.new(5) { |i| web_search_output(call_id: "ws_#{i}") } },
      { 'output' => Array.new(5) { |i| x_search_output(call_id: "xs_#{i}") } },
      { 'output' => Array.new(5) { |i| tool_call(name: hellthread_tool_full_name, call_id: "ht_#{i}") } },
      { 'output' => Array.new(10) { |i| tool_call(name: unusual_whales_tool_full_name, call_id: "uw_#{i}") } },
      { 'output' => [trade_call(trades: [valid_trade])] }
    ]
    xai = FakeXaiClient.new(payloads)

    build_service(xai_client: xai, max_iterations: 10).call

    fifth_tools = xai.calls[4][:tools]
    expect(function_names(fifth_tools)).to include(described_class::FUNCTION_NAME)
    expect(types(fifth_tools)).to include('web_search', 'x_search')
  end
end
