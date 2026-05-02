# frozen_string_literal: true

require 'date'
require_relative '../../lib/trading/market_calendar'

describe Trading::MarketCalendar, '.open?' do
  it 'returns true for an ordinary weekday' do
    expect(described_class.open?(Date.new(2026, 5, 7))).to be true
  end

  it 'returns false on Saturday' do
    expect(described_class.open?(Date.new(2026, 5, 2))).to be false
  end

  it 'returns false on Sunday' do
    expect(described_class.open?(Date.new(2026, 5, 3))).to be false
  end

  it 'accepts a Time and ignores time-of-day' do
    saturday_evening = Time.new(2026, 5, 2, 23, 59, 59)
    expect(described_class.open?(saturday_evening)).to be false
  end

  it 'returns nil from closed_reason for a regular weekday' do
    expect(described_class.closed_reason(Date.new(2026, 5, 7))).to be_nil
  end
end
