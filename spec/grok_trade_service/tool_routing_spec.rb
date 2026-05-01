# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'tool routing' do
  it "returns an error message when the tool prefix isn't a known server" do
    allow(hellthread_client).to receive(:call_tool)
    xai = FakeXaiClient.new([
                              { 'output' => [tool_call(name: 'totally_unknown_tool', call_id: 'x')] },
                              { 'output' => [trade_call(trades: [valid_trade])] }
                            ])
    build_service(xai_client: xai, max_iterations: 3).call

    expect(hellthread_client).not_to have_received(:call_tool)
    output = function_output_from(xai.calls[1][:input])
    expect(output).to include('Unknown tool')
  end

  it 'returns an error when the tool is not found on the labeled server' do
    bogus = tool_call(name: "#{described_class::HELLTHREAD_LABEL}__nope", call_id: 'x')
    xai = FakeXaiClient.new([
                              { 'output' => [bogus] },
                              { 'output' => [trade_call(trades: [valid_trade])] }
                            ])
    build_service(xai_client: xai, max_iterations: 3).call

    expect(function_output_from(xai.calls[1][:input])).to include('not found')
  end

  def function_output_from(input)
    input.find { |i| (i[:type] || i['type']) == 'function_call_output' }[:output]
  end
end
