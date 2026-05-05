# frozen_string_literal: true

require_relative '../../lib/trading/quota_tracker'

module QuotaTrackerHelpers
  def fill_all_quotas(tracker)
    5.times { tracker.record_outputs([{ 'type' => 'web_search_call' }]) }
    5.times { tracker.record_outputs([{ 'type' => 'custom_tool_call', 'name' => 'x_keyword_search' }]) }
    5.times { tracker.record_outputs([{ 'type' => 'function_call', 'name' => 'hellthread__t' }]) }
    10.times { tracker.record_outputs([{ 'type' => 'function_call', 'name' => 'unusual-whales__t' }]) }
    5.times { tracker.record_outputs([{ 'type' => 'function_call', 'name' => 'alpha-vantage__t' }]) }
  end
end

RSpec.configure { |c| c.include QuotaTrackerHelpers }

describe Trading::QuotaTracker, 'category counting' do
  let(:tracker) { described_class.new }

  it 'increments web_search on web_search_call output items' do
    tracker.record_outputs([{ 'type' => 'web_search_call' }, { 'type' => 'web_search_call' }])
    expect(tracker.counts['web_search']).to eq(2)
  end

  it 'increments x_search on custom_tool_call output items' do
    tracker.record_outputs([{ 'type' => 'custom_tool_call', 'name' => 'x_keyword_search' }])
    expect(tracker.counts['x_search']).to eq(1)
  end

  it 'increments hellthread and unusual-whales on namespaced function_calls' do
    tracker.record_outputs([
                             { 'type' => 'function_call', 'name' => 'hellthread__search_4chan' },
                             { 'type' => 'function_call', 'name' => 'unusual-whales__flow_alerts' }
                           ])
    expect(tracker.counts['hellthread']).to eq(1)
    expect(tracker.counts['unusual-whales']).to eq(1)
  end

  it 'ignores trade_recommendations and unrecognized items' do
    tracker.record_outputs([{ 'type' => 'function_call', 'name' => 'trade_recommendations' },
                            { 'type' => 'reasoning' }, { 'type' => 'message' }])
    expect(tracker.counts.values.sum).to eq(0)
  end
end

describe Trading::QuotaTracker, 'quota predicates' do
  let(:tracker) { described_class.new }

  it 'reports unmet categories until quotas are filled' do
    4.times { tracker.record_outputs([{ 'type' => 'web_search_call' }]) }
    expect(tracker.met?('web_search')).to be(false)
    expect(tracker.unmet_categories).to include('web_search')
  end

  it 'flags a category as met once its count reaches the quota' do
    5.times { tracker.record_outputs([{ 'type' => 'web_search_call' }]) }
    expect(tracker.met?('web_search')).to be(true)
    expect(tracker.unmet_categories).not_to include('web_search')
  end

  it 'reports all_met? only when every category has been satisfied' do
    fill_all_quotas(tracker)
    expect(tracker).to be_all_met
  end
end
