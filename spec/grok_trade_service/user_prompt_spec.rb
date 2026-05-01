# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'user prompt' do
  let(:position) { described_class::Position.new(type: 'stock', symbol: 'AAPL', quantity: 100, position_type: 'long') }

  def first_user_content(service)
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])
    service.instance_variable_set(:@config, service.instance_variable_get(:@config).dup.tap do |cfg|
      cfg.xai_client_factory = xai.factory
    end)
    service.call
    xai.calls.first[:input].find { |i| i[:role] == 'user' }[:content]
  end

  it 'includes the liquidity amount and core sections' do
    content = first_user_content(build_service(liquidity_amount: 12_345))
    expect(content).to include('12345').and include('confidence').and include('reasoning')
  end

  it 'includes a positions section when positions are provided' do
    content = first_user_content(build_service(positions: [position]))
    expect(content).to include('100 shares of AAPL').and include('current positions')
  end
end
