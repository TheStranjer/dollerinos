# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

module XaiToolSpecPhaseHelpers
  def tools_by_label
    {
      Trading::Constants::HELLTHREAD_LABEL => [hellthread_tool],
      Trading::Constants::UNUSUAL_WHALES_LABEL => [unusual_whales_tool],
      Trading::Constants::ALPHA_VANTAGE_LABEL => [alpha_vantage_tool]
    }
  end

  def fill_all_quotas(tracker)
    5.times { tracker.record_outputs([{ 'type' => 'web_search_call' }]) }
    5.times { tracker.record_outputs([{ 'type' => 'custom_tool_call', 'name' => 'x_search' }]) }
    5.times { tracker.record_outputs([{ 'type' => 'function_call', 'name' => 'hellthread__t' }]) }
    10.times { tracker.record_outputs([{ 'type' => 'function_call', 'name' => 'unusual-whales__t' }]) }
    5.times { tracker.record_outputs([{ 'type' => 'function_call', 'name' => 'alpha-vantage__t' }]) }
  end
end

RSpec.configure { |c| c.include XaiToolSpecPhaseHelpers }

describe Trading::XaiToolSpecs, 'gather phase' do
  let(:tracker) { Trading::QuotaTracker.new }
  let(:specs) { described_class.new(tools_by_label, quota_tracker: tracker) }

  it 'omits trade_recommendations and met categories' do
    5.times { tracker.record_outputs([{ 'type' => 'web_search_call' }]) }
    5.times { tracker.record_outputs([{ 'type' => 'function_call', 'name' => 'hellthread__t' }]) }

    tools = specs.build(phase: :gather)
    types = tools.map { |t| t[:type] }
    names = tools.map { |t| t[:name] }.compact

    expect(names).not_to include(Trading::Constants::FUNCTION_NAME)
    expect(types).not_to include('web_search')
    expect(names).not_to include(hellthread_tool_full_name)
    expect(types).to include('x_search')
    expect(names).to include(unusual_whales_tool_full_name)
  end

  it 'returns an empty list once every quota is met' do
    fill_all_quotas(tracker)
    expect(specs.build(phase: :gather)).to eq([])
  end
end

describe Trading::XaiToolSpecs, 'open phase' do
  let(:tracker) { Trading::QuotaTracker.new }
  let(:specs) { described_class.new(tools_by_label, quota_tracker: tracker) }

  it 'exposes search tools, all MCP tools, and trade_recommendations' do
    fill_all_quotas(tracker)

    tools = specs.build(phase: :open)
    types = tools.map { |t| t[:type] }
    names = tools.map { |t| t[:name] }.compact

    expect(types).to include('x_search', 'web_search')
    expect(names).to include(
      hellthread_tool_full_name, unusual_whales_tool_full_name,
      alpha_vantage_tool_full_name, Trading::Constants::FUNCTION_NAME
    )
  end
end

describe Trading::XaiToolSpecs, 'force_trade_recs phase' do
  let(:tracker) { Trading::QuotaTracker.new }
  let(:specs) { described_class.new(tools_by_label, quota_tracker: tracker) }

  it 'returns trade_recommendations as the only tool' do
    tools = specs.build(phase: :force_trade_recs)
    expect(tools.size).to eq(1)
    expect(tools.first[:name]).to eq(Trading::Constants::FUNCTION_NAME)
  end

  it 'raises on unknown phases' do
    expect { specs.build(phase: :weird) }.to raise_error(ArgumentError)
  end
end
