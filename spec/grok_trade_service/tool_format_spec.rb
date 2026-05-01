# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'tool result formatting' do
  it 'joins multiple text content items with newlines' do
    allow(hellthread_client).to receive(:call_tool).and_return(
      'result' => { 'content' => [{ 'type' => 'text', 'text' => 'one' }, { 'type' => 'text', 'text' => 'two' }] }
    )
    output = run_with_one_tool_call

    expect(output).to eq("one\ntwo")
  end

  it 'falls back to JSON when content is missing' do
    allow(hellthread_client).to receive(:call_tool).and_return('result' => { 'structuredContent' => { 'ok' => true } })
    expect(JSON.parse(run_with_one_tool_call)).to eq('ok' => true)
  end

  it 'wraps tool execution exceptions into an error string fed back to the model' do
    allow(hellthread_client).to receive(:call_tool).and_raise(StandardError.new('boom'))
    expect(run_with_one_tool_call).to include('boom')
  end

  def run_with_one_tool_call
    xai = FakeXaiClient.new([
                              { 'output' => [tool_call(name: hellthread_tool_full_name, call_id: 'ht_1')] },
                              { 'output' => [trade_call(trades: [valid_trade])] }
                            ])
    build_service(xai_client: xai).call
    xai.calls[1][:input].find { |i| (i[:type] || i['type']) == 'function_call_output' }[:output]
  end
end
