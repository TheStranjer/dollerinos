# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'last iteration' do
  it 'passes only trade_recommendations and a forcing tool_choice on the final iteration' do
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])

    build_service(xai_client: xai, max_iterations: 1).call

    captured = xai.calls.first
    expect(captured[:tools].map { |t| t[:name] || t[:type] }).to eq([described_class::FUNCTION_NAME])
    expect(captured[:tool_choice]).to eq(type: 'function', name: described_class::FUNCTION_NAME)
  end

  it "uses 'required' tool_choice during the gather phase" do
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])

    build_service(xai_client: xai, max_iterations: 5).call

    expect(xai.calls.first[:tool_choice]).to eq('required')
  end
end
