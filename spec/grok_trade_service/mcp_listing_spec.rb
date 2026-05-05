# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'MCP tool listing' do
  it 'lists tools from each configured server' do
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])

    build_service(xai_client: xai).call

    expect(hellthread_client).to have_received(:tools)
    expect(unusual_whales_client).to have_received(:tools)
    expect(alpha_vantage_client).to have_received(:tools)
  end
end
