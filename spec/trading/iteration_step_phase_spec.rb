# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::IterationStep, 'phase selection' do
  let(:tracker) { Trading::QuotaTracker.new }

  it 'returns :gather while quotas are unmet and iteration is below max' do
    step = described_class.new(iteration: 1, max_iterations: 10, quota_tracker: tracker)

    expect(step.phase).to eq(:gather)
    expect(step.tool_choice).to eq('required')
  end

  it 'returns :open once every quota is met but max has not yet been reached' do
    fill_quotas(tracker)
    step = described_class.new(iteration: 5, max_iterations: 10, quota_tracker: tracker)

    expect(step.phase).to eq(:open)
    expect(step.tool_choice).to eq('auto')
  end

  it 'returns :force_trade_recs on the final iteration regardless of quota state' do
    step = described_class.new(iteration: 10, max_iterations: 10, quota_tracker: tracker)

    expect(step.phase).to eq(:force_trade_recs)
    expect(step.tool_choice).to eq(type: 'function', name: Trading::Constants::FUNCTION_NAME)
  end

  def fill_quotas(tracker)
    5.times { tracker.record_outputs([{ 'type' => 'web_search_call' }]) }
    5.times { tracker.record_outputs([{ 'type' => 'custom_tool_call', 'name' => 'x_search' }]) }
    5.times { tracker.record_outputs([{ 'type' => 'function_call', 'name' => 'hellthread__t' }]) }
    10.times { tracker.record_outputs([{ 'type' => 'function_call', 'name' => 'unusual-whales__t' }]) }
  end
end
