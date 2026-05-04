# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'market status: weekend' do
  it 'tells the model the market is closed when invoked on a weekend' do
    saturday = Time.new(2026, 5, 2, 9, 30, 0)
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])

    build_service(xai_client: xai, now: saturday).call

    system_content = xai.calls.first[:input].first[:content]
    expect(system_content).to include('CLOSED')
    expect(system_content).to include('weekend')
    expect(system_content).to include('stock and ETF')
  end
end

describe Trading::GrokTradeService, 'market status: U.S. holiday' do
  it 'tells the model the market is closed when invoked on a U.S. holiday' do
    christmas = Time.new(2025, 12, 25, 9, 30, 0)
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])

    build_service(xai_client: xai, now: christmas).call

    system_content = xai.calls.first[:input].first[:content]
    expect(system_content).to include('CLOSED')
    expect(system_content).to include('holiday')
    expect(system_content).to include('stock and ETF')
  end
end

describe Trading::GrokTradeService, 'market status: after-hours weekday' do
  it 'restricts to stocks/ETFs after-hours on a regular trading day' do
    after_hours = Time.new(2026, 5, 7, 18, 0, 0, '-04:00')
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])

    build_service(xai_client: xai, now: after_hours).call

    system_content = xai.calls.first[:input].first[:content]
    expect(system_content).to include('CLOSED')
    expect(system_content).to include('after-hours')
    expect(system_content).to include('stock and ETF')
    expect(system_content).to match(/Do NOT recommend options/i)
  end
end

describe Trading::GrokTradeService, 'market status: regular session' do
  it 'omits the market-closed notice during regular session hours' do
    during_session = Time.new(2026, 5, 7, 11, 0, 0, '-04:00')
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])

    build_service(xai_client: xai, now: during_session).call

    system_content = xai.calls.first[:input].first[:content]
    expect(system_content).not_to include('CLOSED')
    expect(system_content).not_to include('after-hours')
  end
end
