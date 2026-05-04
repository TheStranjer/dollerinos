# frozen_string_literal: true

require 'date'
require_relative '../../lib/trading/system_prompt'

EDT_OFFSET = '-04:00' unless defined?(EDT_OFFSET)
EST_OFFSET = '-05:00' unless defined?(EST_OFFSET)

describe Trading::SystemPrompt, '.for_iteration during after-hours' do
  let(:after_close) { Time.new(2026, 5, 7, 18, 0, 0, EDT_OFFSET) }
  let(:pre_open) { Time.new(2026, 5, 7, 7, 0, 0, EDT_OFFSET) }

  it 'restricts recommendations to stocks/ETFs after the closing bell' do
    content = described_class.for_iteration(1, 5, now: after_close)
    expect(content).to include('CLOSED')
    expect(content).to include('after-hours')
    expect(content).to include('stock and ETF')
    expect(content).to match(/Do NOT recommend options/i)
  end

  it 'restricts recommendations to stocks/ETFs during pre-market' do
    content = described_class.for_iteration(1, 5, now: pre_open)
    expect(content).to include('CLOSED')
    expect(content).to include('after-hours')
    expect(content).to include('stock and ETF')
  end

  it 'mentions the broker only supports 24/5 stock trading' do
    content = described_class.for_iteration(1, 5, now: after_close)
    expect(content).to include('24/5')
  end
end

describe Trading::SystemPrompt, '.for_iteration during the regular session' do
  let(:during_session) { Time.new(2026, 5, 7, 11, 0, 0, EDT_OFFSET) }

  it 'omits the closed notice' do
    content = described_class.for_iteration(1, 5, now: during_session)
    expect(content).not_to include('CLOSED')
    expect(content).not_to include('after-hours')
  end
end

describe Trading::SystemPrompt, '.for_iteration FINAL iteration after-hours' do
  let(:after_close) { Time.new(2026, 5, 7, 18, 0, 0, EDT_OFFSET) }

  it 'still includes the FINAL directive on the last iteration' do
    content = described_class.for_iteration(3, 3, now: after_close, phase: :force_trade_recs)
    expect(content).to include('FINAL iteration')
    expect(content).to include('CLOSED')
    expect(content).to include('after-hours')
  end
end
