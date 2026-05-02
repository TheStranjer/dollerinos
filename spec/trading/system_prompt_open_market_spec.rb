# frozen_string_literal: true

require 'date'
require_relative '../../lib/trading/system_prompt'

describe Trading::SystemPrompt, '.for_iteration on open-market days' do
  let(:weekday) { Time.new(2026, 5, 7, 9, 30, 0) }

  it 'omits the market-closed notice on a regular weekday' do
    content = described_class.for_iteration(1, 5, now: weekday)
    expect(content).not_to include('CLOSED')
    expect(content).not_to include('after hours')
  end
end
