# frozen_string_literal: true

require 'date'
require_relative '../../lib/trading/system_prompt'

describe Trading::SystemPrompt, '.for_iteration current-time exposure' do
  let(:now) { Time.new(2026, 5, 7, 9, 30, 15, '-04:00') }

  it 'includes a current-time line with weekday, date, time, and timezone offset' do
    content = described_class.for_iteration(1, 5, now: now)
    expect(content).to include('Current time at the start of this run:')
    expect(content).to include('Thursday')
    expect(content).to include('2026-05-07')
    expect(content).to include('09:30:15')
    expect(content).to include('UTC-04:00')
  end

  it 'still exposes the current-time line on closed-market days' do
    weekend = Time.new(2026, 5, 2, 9, 30, 0, '-04:00')
    content = described_class.for_iteration(1, 5, now: weekend)
    expect(content).to include('Current time at the start of this run:')
    expect(content).to include('Saturday')
    expect(content).to include('2026-05-02')
  end

  it 'reports the same time across iterations when given the same now' do
    content_a = described_class.for_iteration(1, 5, now: now)
    content_b = described_class.for_iteration(4, 5, now: now, phase: :open)
    time_line_a = content_a[/Current time at the start of this run:[^\n]+/]
    time_line_b = content_b[/Current time at the start of this run:[^\n]+/]
    expect(time_line_a).to eq(time_line_b)
  end
end
