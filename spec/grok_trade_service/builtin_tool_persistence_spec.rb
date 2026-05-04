# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'web_search call persistence' do
  it 'forwards previous web_search_call output items into subsequent iterations input' do
    web_call_a = web_search_output(call_id: 'ws_1').merge(
      'action' => { 'type' => 'search', 'query' => 'AAPL squeeze', 'sources' => [] }
    )
    web_call_b = web_search_output(call_id: 'ws_2').merge(
      'action' => { 'type' => 'search', 'query' => 'AAPL earnings', 'sources' => [] }
    )
    xai = FakeXaiClient.new([
                              { 'output' => [web_call_a, web_call_b] },
                              { 'output' => [trade_call(trades: [valid_trade])] }
                            ])

    build_service(xai_client: xai).call

    second_input = xai.calls[1][:input]
    expect(second_input).to include(web_call_a, web_call_b)
  end
end

describe Trading::GrokTradeService, 'x_keyword_search call persistence' do
  it 'forwards previous x_keyword_search custom_tool_call output items into subsequent iterations input' do
    x_call = x_search_output(name: 'x_keyword_search', call_id: 'xs_7').merge(
      'input' => '{"query":"$AAPL since:2026-05-03","limit":"10","mode":"Latest"}'
    )
    xai = FakeXaiClient.new([
                              { 'output' => [x_call] },
                              { 'output' => [trade_call(trades: [valid_trade])] }
                            ])

    build_service(xai_client: xai).call

    second_input = xai.calls[1][:input]
    expect(second_input).to include(x_call)
  end
end

describe Trading::GrokTradeService, 'built-in tool persistence across many iterations' do
  it 'preserves built-in tool call output items across every iteration, not only the immediate next one' do
    web_call = web_search_output(call_id: 'ws_keep')
    x_call = x_search_output(name: 'x_keyword_search', call_id: 'xs_keep')
    allow(hellthread_client).to receive(:call_tool).and_return(text_result('biz buzz'))

    xai = FakeXaiClient.new([
                              { 'output' => [web_call, x_call] },
                              { 'output' => [tool_call(name: hellthread_tool_full_name, call_id: 'ht_1')] },
                              { 'output' => [trade_call(trades: [valid_trade])] }
                            ])

    build_service(xai_client: xai).call

    third_input = xai.calls[2][:input]
    expect(third_input).to include(web_call, x_call)
  end
end

describe Trading::GrokTradeService, 'built-in tool persistence interleaved with function calls' do
  it 'preserves built-in tool call output items even when interleaved with function calls in the same turn' do
    web_call = web_search_output(call_id: 'ws_inter')
    fn_call = tool_call(name: hellthread_tool_full_name, arguments: { 'query' => 'AAPL' }, call_id: 'ht_inter')
    allow(hellthread_client).to receive(:call_tool).and_return(text_result('biz buzz'))

    xai = FakeXaiClient.new([
                              { 'output' => [web_call, fn_call] },
                              { 'output' => [trade_call(trades: [valid_trade])] }
                            ])

    build_service(xai_client: xai).call

    second_input = xai.calls[1][:input]
    expect(second_input).to include(web_call)
    function_outputs = second_input.select { |i| (i[:type] || i['type']) == 'function_call_output' }
    expect(function_outputs.size).to eq(1)
  end
end
