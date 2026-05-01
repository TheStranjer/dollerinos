# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'single iteration' do
  it 'returns trades when xAI responds with trade_recommendations on the first turn' do
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])],
                               'usage' => { 'input_tokens' => 100, 'output_tokens' => 50 } }])
    result = build_service(xai_client: xai).call

    expect(result).to be_success
    expect(result.trades.first.symbol).to eq('AAPL')
    expect(result.iterations).to eq(1)
    expect(result.usage).to include('input_tokens' => 100, 'output_tokens' => 50)
  end

  it 'filters invalid trades from the trade_recommendations call' do
    bad = valid_trade.merge('symbol' => '')
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade, bad])] }])
    result = build_service(xai_client: xai).call

    expect(result.trades.size).to eq(1)
    expect(result.trades.first.symbol).to eq('AAPL')
  end

  it 'fails when the trade_recommendations payload contains no valid trades' do
    bad = valid_trade.merge('symbol' => '')
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [bad])] }])
    expect(build_service(xai_client: xai).call.error_message).to include('no valid')
  end
end
