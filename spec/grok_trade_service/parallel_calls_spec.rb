# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'parallel tool calls' do
  it 'executes multiple tool calls in a single iteration' do
    allow(hellthread_client).to receive(:call_tool).and_return(text_result('biz output'))
    allow(unusual_whales_client).to receive(:call_tool).and_return(text_result('uw output'))
    xai = FakeXaiClient.new([parallel_response, finishing_response])

    result = build_service(xai_client: xai).call

    expect(result).to be_success
    expect(result.iterations).to eq(2)
    expect(hellthread_client).to have_received(:call_tool).once
    expect(unusual_whales_client).to have_received(:call_tool).once
    second_input = xai.calls[1][:input]
    expect(second_input.count { |i| (i[:type] || i['type']) == 'function_call_output' }).to eq(2)
  end

  def parallel_response
    {
      'output' => [
        tool_call(name: hellthread_tool_full_name, arguments: { 'query' => 'AAPL' }, call_id: 'ht_1'),
        tool_call(name: unusual_whales_tool_full_name, arguments: { 'ticker' => 'AAPL' }, call_id: 'uw_1')
      ]
    }
  end

  def finishing_response
    { 'output' => [trade_call(trades: [valid_trade])] }
  end
end
