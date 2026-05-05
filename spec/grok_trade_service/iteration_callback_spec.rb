# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

class RecordingListener
  attr_reader :events

  def initialize
    @events = []
  end

  def iteration_started(**payload)
    @events << { event: :iteration_started, **payload }
  end

  def model_output(**payload)
    @events << { event: :model_output, **payload }
  end

  def tool_call_started(**payload)
    @events << { event: :tool_call_started, **payload }
  end

  def tool_call_completed(**payload)
    @events << { event: :tool_call_completed, **payload }
  end

  def iteration_finished(**payload)
    @events << { event: :iteration_finished, **payload }
  end
end

module IterationListenerHelpers
  def two_turn_xai
    FakeXaiClient.new([
                        { 'output' => [tool_call(name: hellthread_tool_full_name, call_id: 'ht_1')] },
                        { 'output' => [trade_call(trades: [valid_trade])] }
                      ])
  end

  def single_turn_xai
    FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])
  end
end

RSpec.configure { |c| c.include IterationListenerHelpers }

describe Trading::GrokTradeService, 'iteration listener ordering' do
  it 'announces the iteration before the xAI response is processed' do
    allow(hellthread_client).to receive(:call_tool).and_return(text_result('ok'))
    listener = RecordingListener.new
    build_service(xai_client: two_turn_xai, on_iteration: listener).call

    types = listener.events.map { |e| e[:event] }
    expect(types.index(:iteration_started)).to be < types.index(:model_output)
  end

  it 'orders started before completed for each tool call' do
    allow(hellthread_client).to receive(:call_tool).and_return(text_result('ok'))
    listener = RecordingListener.new
    build_service(xai_client: two_turn_xai, on_iteration: listener).call

    sequence = listener.events.map { |e| e[:event] }
    expect(sequence.index(:tool_call_started)).to be < sequence.index(:tool_call_completed)
  end
end

describe Trading::GrokTradeService, 'iteration_started payload' do
  it 'emits iteration_started with phase, tool list, and tool_choice' do
    listener = RecordingListener.new
    build_service(xai_client: single_turn_xai, on_iteration: listener).call

    started = listener.events.find { |e| e[:event] == :iteration_started }
    expect(started[:iteration]).to eq(1)
    expect(started[:max_iterations]).to eq(described_class::MAX_ITERATIONS)
    expect(started[:phase]).to eq(:gather)
    expect(started[:tool_choice]).to eq('required')
    expect(started[:tools]).to be_an(Array)
    expect(started[:tools]).not_to be_empty
  end
end

describe Trading::GrokTradeService, 'tool call dispatch events' do
  it 'emits a tool_call_started and tool_call_completed event for each dispatched tool call' do
    allow(hellthread_client).to receive(:call_tool).and_return(text_result('biz says AAPL'))
    listener = RecordingListener.new
    build_service(xai_client: two_turn_xai, on_iteration: listener).call

    started = listener.events.select { |e| e[:event] == :tool_call_started }
    completed = listener.events.select { |e| e[:event] == :tool_call_completed }
    expect(started.size).to eq(1)
    expect(completed.size).to eq(1)
    expect(started.first[:function_call]['name']).to start_with(described_class::HELLTHREAD_LABEL)
    expect(completed.first[:result][:result]).to include('biz says AAPL')
  end
end

describe Trading::GrokTradeService, 'iteration_finished event' do
  it 'fires iteration_finished after the iteration concludes' do
    listener = RecordingListener.new
    build_service(xai_client: single_turn_xai, on_iteration: listener).call

    finished = listener.events.select { |e| e[:event] == :iteration_finished }
    expect(finished.size).to eq(1)
    expect(finished.first[:iteration]).to eq(1)
  end
end
