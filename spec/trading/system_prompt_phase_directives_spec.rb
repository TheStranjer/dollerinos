# frozen_string_literal: true

require_relative '../../lib/trading/system_prompt'
require_relative '../../lib/trading/constants'

OPEN_MARKET_NOW = Time.new(2026, 5, 7, 11, 0, 0, '-04:00') unless defined?(OPEN_MARKET_NOW)

describe Trading::SystemPrompt, '.for_iteration in the gather phase' do
  it 'does not mention trade_recommendations while gated' do
    content = described_class.for_iteration(
      1, 10, now: OPEN_MARKET_NOW, phase: :gather, unmet_categories: %w[hellthread web_search]
    )

    expect(content).not_to include(Trading::Constants::FUNCTION_NAME)
  end

  it 'omits put-options schema guidance while gated' do
    content = described_class.for_iteration(1, 10, now: OPEN_MARKET_NOW, phase: :gather, unmet_categories: [])

    expect(content).not_to match(/option_type/)
    expect(content).not_to match(/put options/i)
  end

  it 'tells the model it needs more research before a determination' do
    content = described_class.for_iteration(
      1, 10, now: OPEN_MARKET_NOW, phase: :gather, unmet_categories: %w[hellthread]
    )

    expect(content).to match(/research/i)
    expect(content).to match(/determination|enough information/i)
    expect(content).to include('hellthread')
  end
end

describe Trading::SystemPrompt, '.for_iteration in the open phase' do
  it 'tells the model to follow every lead until really sure' do
    content = described_class.for_iteration(5, 10, now: OPEN_MARKET_NOW, phase: :open)

    expect(content).to match(/follow every (promising )?lead/i)
    expect(content).to match(/really sure/i)
  end

  it 'mentions trade_recommendations as a finalization option' do
    content = described_class.for_iteration(5, 10, now: OPEN_MARKET_NOW, phase: :open)

    expect(content).to include(Trading::Constants::FUNCTION_NAME)
  end

  it 'restores the put-options schema guidance once the finalizer is in scope' do
    content = described_class.for_iteration(5, 10, now: OPEN_MARKET_NOW, phase: :open)

    expect(content).to match(/option_type/)
  end
end

describe Trading::SystemPrompt, '.for_iteration in the force_trade_recs phase' do
  it 'tells the model it is time to make a decision' do
    content = described_class.for_iteration(10, 10, now: OPEN_MARKET_NOW, phase: :force_trade_recs)

    expect(content).to match(/time to make a decision/i)
    expect(content).to include('FINAL iteration')
  end

  it 'forces a trade_recommendations call' do
    content = described_class.for_iteration(10, 10, now: OPEN_MARKET_NOW, phase: :force_trade_recs)

    expect(content).to include(Trading::Constants::FUNCTION_NAME)
    expect(content).to match(/MUST call it/)
  end
end
