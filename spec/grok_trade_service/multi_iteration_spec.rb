# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'multi-iteration loop' do
  it 'feeds an MCP tool result back into the next turn' do
    allow(hellthread_client).to receive(:call_tool).and_return(text_result('biz says AAPL squeeze'))
    first_call = tool_call(name: hellthread_tool_full_name, arguments: { 'query' => 'AAPL' }, call_id: 'ht_1')
    xai = FakeXaiClient.new([
                              { 'output' => [first_call] },
                              { 'output' => [trade_call(trades: [valid_trade])] }
                            ])
    result = build_service(xai_client: xai).call

    expect(result).to be_success
    expect(result.iterations).to eq(2)
    expect(hellthread_client).to have_received(:call_tool).with(tool: hellthread_tool, arguments: { 'query' => 'AAPL' })
  end

  it 'accumulates token usage across iterations' do
    allow(hellthread_client).to receive(:call_tool).and_return(text_result('ok'))
    xai = FakeXaiClient.new([
                              { 'output' => [tool_call(name: hellthread_tool_full_name, call_id: 'ht_1')],
                                'usage' => { 'input_tokens' => 100 } },
                              { 'output' => [trade_call(trades: [valid_trade])], 'usage' => { 'input_tokens' => 80 } }
                            ])
    expect(build_service(xai_client: xai).call.usage['input_tokens']).to eq(180)
  end
end
