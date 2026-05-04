# frozen_string_literal: true

require 'date'
require_relative '../../lib/trading/market_calendar'

EDT_OFFSET = '-04:00'
EST_OFFSET = '-05:00'

describe Trading::MarketCalendar, '.regular_session_open? within session hours' do
  it 'is true at 9:30 ET (open of session)' do
    open_bell = Time.new(2026, 5, 7, 9, 30, 0, EDT_OFFSET)
    expect(described_class.regular_session_open?(open_bell)).to be true
  end

  it 'is true mid-session' do
    midday = Time.new(2026, 5, 7, 12, 0, 0, EDT_OFFSET)
    expect(described_class.regular_session_open?(midday)).to be true
  end

  it 'is true one minute before close' do
    near_close = Time.new(2026, 5, 7, 15, 59, 0, EDT_OFFSET)
    expect(described_class.regular_session_open?(near_close)).to be true
  end
end

describe Trading::MarketCalendar, '.regular_session_open? outside session hours' do
  it 'is false at 16:00 ET (closing bell)' do
    close_bell = Time.new(2026, 5, 7, 16, 0, 0, EDT_OFFSET)
    expect(described_class.regular_session_open?(close_bell)).to be false
  end

  it 'is false in the pre-market window' do
    pre_market = Time.new(2026, 5, 7, 8, 0, 0, EDT_OFFSET)
    expect(described_class.regular_session_open?(pre_market)).to be false
  end

  it 'is false right before the bell (9:29 ET)' do
    pre_bell = Time.new(2026, 5, 7, 9, 29, 0, EDT_OFFSET)
    expect(described_class.regular_session_open?(pre_bell)).to be false
  end

  it 'is false in the after-hours window' do
    after_hours = Time.new(2026, 5, 7, 18, 0, 0, EDT_OFFSET)
    expect(described_class.regular_session_open?(after_hours)).to be false
  end
end

describe Trading::MarketCalendar, '.regular_session_open? on closed days' do
  it 'is false on a Saturday during would-be regular hours' do
    saturday_noon = Time.new(2026, 5, 2, 12, 0, 0, EDT_OFFSET)
    expect(described_class.regular_session_open?(saturday_noon)).to be false
  end

  it 'is false on Christmas during would-be regular hours' do
    christmas_noon = Time.new(2025, 12, 25, 12, 0, 0, EST_OFFSET)
    expect(described_class.regular_session_open?(christmas_noon)).to be false
  end
end

describe Trading::MarketCalendar, '.regular_session_open? input handling' do
  it 'converts non-ET local time to ET before applying the hours window' do
    pt_morning = Time.new(2026, 5, 7, 9, 0, 0, '-07:00')
    expect(described_class.regular_session_open?(pt_morning)).to be true
  end

  it 'falls back to date-only behavior when given a Date for a trading day' do
    expect(described_class.regular_session_open?(Date.new(2026, 5, 7))).to be true
  end

  it 'falls back to date-only behavior when given a Date for a weekend' do
    expect(described_class.regular_session_open?(Date.new(2026, 5, 2))).to be false
  end
end

describe Trading::MarketCalendar, '.closed_reason with intraday times' do
  it 'returns "after-hours" on a trading day before the bell' do
    pre_market = Time.new(2026, 5, 7, 7, 0, 0, EDT_OFFSET)
    expect(described_class.closed_reason(pre_market)).to eq('after-hours')
  end

  it 'returns "after-hours" on a trading day after the close' do
    after_hours = Time.new(2026, 5, 7, 17, 30, 0, EDT_OFFSET)
    expect(described_class.closed_reason(after_hours)).to eq('after-hours')
  end

  it 'returns nil during the regular session' do
    midday = Time.new(2026, 5, 7, 13, 0, 0, EDT_OFFSET)
    expect(described_class.closed_reason(midday)).to be_nil
  end

  it 'still prefers "weekend" over "after-hours" when both apply' do
    saturday_after_hours = Time.new(2026, 5, 2, 18, 0, 0, EDT_OFFSET)
    expect(described_class.closed_reason(saturday_after_hours)).to eq('weekend')
  end

  it 'still prefers "holiday" over "after-hours" when both apply' do
    christmas_after_hours = Time.new(2025, 12, 25, 18, 0, 0, EST_OFFSET)
    expect(described_class.closed_reason(christmas_after_hours)).to eq('holiday')
  end
end
