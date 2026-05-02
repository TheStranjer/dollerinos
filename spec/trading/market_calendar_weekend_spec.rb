# frozen_string_literal: true

require 'date'
require_relative '../../lib/trading/market_calendar'

describe Trading::MarketCalendar, 'weekend handling' do
  it 'returns "weekend" for a Saturday' do
    expect(described_class.closed_reason(Date.new(2026, 5, 2))).to eq('weekend')
  end

  it 'returns "weekend" for a Sunday' do
    expect(described_class.closed_reason(Date.new(2026, 5, 3))).to eq('weekend')
  end
end
