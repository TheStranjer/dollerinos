# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'market status in system prompt' do
  it 'tells the model the market is closed when invoked on a weekend' do
    saturday = Time.new(2026, 5, 2, 9, 30, 0)
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])

    build_service(xai_client: xai, now: saturday).call

    system_content = xai.calls.first[:input].first[:content]
    expect(system_content).to include('CLOSED')
    expect(system_content).to include('"after hours"')
  end

  it 'tells the model the market is closed when invoked on a U.S. holiday' do
    christmas = Time.new(2025, 12, 25, 9, 30, 0)
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])

    build_service(xai_client: xai, now: christmas).call

    system_content = xai.calls.first[:input].first[:content]
    expect(system_content).to include('CLOSED')
    expect(system_content).to include('"after hours"')
  end

  it 'omits the market-closed notice on an open trading day' do
    weekday = Time.new(2026, 5, 7, 9, 30, 0)
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])

    build_service(xai_client: xai, now: weekday).call

    system_content = xai.calls.first[:input].first[:content]
    expect(system_content).not_to include('CLOSED')
    expect(system_content).not_to include('after hours')
  end
end
