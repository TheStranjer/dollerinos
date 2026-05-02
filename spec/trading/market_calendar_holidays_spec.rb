# frozen_string_literal: true

require 'date'
require_relative '../../lib/trading/market_calendar'

HOLIDAY_FIXTURES = {
  "New Year's Day" => Date.new(2026, 1, 1),
  'MLK Day (3rd Mon Jan)' => Date.new(2026, 1, 19),
  'Presidents Day (3rd Mon Feb)' => Date.new(2026, 2, 16),
  'Good Friday' => Date.new(2025, 4, 18),
  'Memorial Day (last Mon May)' => Date.new(2025, 5, 26),
  'Juneteenth' => Date.new(2025, 6, 19),
  'Independence Day' => Date.new(2025, 7, 4),
  'Labor Day (1st Mon Sep)' => Date.new(2025, 9, 1),
  'Thanksgiving (4th Thu Nov)' => Date.new(2025, 11, 27),
  'Christmas Day' => Date.new(2025, 12, 25)
}.freeze

describe Trading::MarketCalendar, 'holiday handling' do
  HOLIDAY_FIXTURES.each do |name, date|
    it "treats #{name} as a holiday" do
      expect(described_class.closed_reason(date)).to eq('holiday')
    end
  end

  it 'observes holidays falling on Saturday on the preceding Friday' do
    expect(described_class.closed_reason(Date.new(2027, 12, 24))).to eq('holiday')
  end

  it 'observes holidays falling on Sunday on the following Monday' do
    expect(described_class.closed_reason(Date.new(2022, 12, 26))).to eq('holiday')
  end
end
