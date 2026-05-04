# frozen_string_literal: true

require 'date'
require_relative '../../lib/trading/system_prompt'

CLOSED_DAY_FIXTURES = {
  'Saturday' => Time.new(2026, 5, 2, 9, 30, 0),
  'Sunday' => Time.new(2026, 5, 3, 9, 30, 0),
  'Christmas Day' => Time.new(2025, 12, 25, 9, 30, 0),
  "New Year's Day" => Time.new(2026, 1, 1, 9, 30, 0)
}.freeze

describe Trading::SystemPrompt, '.for_iteration on closed-market days' do
  CLOSED_DAY_FIXTURES.each do |label, now|
    it "announces the market is closed and limits choices to stocks/ETFs on #{label}" do
      content = described_class.for_iteration(1, 5, now: now)
      expect(content).to include('CLOSED')
      expect(content).to include('after-hours')
      expect(content).to include('stock and ETF')
      expect(content).to match(/Do NOT recommend options/i)
    end
  end

  it 'names the closed-market reason in the notice' do
    content_weekend = described_class.for_iteration(1, 5, now: CLOSED_DAY_FIXTURES['Saturday'])
    content_holiday = described_class.for_iteration(1, 5, now: CLOSED_DAY_FIXTURES['Christmas Day'])
    expect(content_weekend).to include('weekend')
    expect(content_holiday).to include('holiday')
  end

  it 'still includes the iteration progress line when the market is closed' do
    content = described_class.for_iteration(2, 5, now: CLOSED_DAY_FIXTURES['Saturday'])
    expect(content).to include('iteration 2/5')
  end

  it 'still emits the FINAL directive on the last iteration when the market is closed' do
    content = described_class.for_iteration(5, 5, now: CLOSED_DAY_FIXTURES['Saturday'])
    expect(content).to include('FINAL iteration')
    expect(content).to include('CLOSED')
  end
end
