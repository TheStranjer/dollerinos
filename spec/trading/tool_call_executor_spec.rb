# frozen_string_literal: true

require_relative '../../lib/trading/tool_call_executor'

module ToolCallExecutorHelpers
  def fake_state
    Class.new do
      attr_reader :outputs

      def initialize
        @outputs = []
      end

      def append_function_output(call_id, text)
        @outputs << [call_id, text]
      end
    end.new
  end

  def fake_dispatcher(result: 'ok')
    dispatcher = Object.new
    dispatcher.define_singleton_method(:dispatch) { |_fc| result }
    dispatcher
  end

  def recording_sleeper
    Class.new do
      attr_reader :sleeps

      def initialize
        @sleeps = []
      end

      def sleep(seconds)
        @sleeps << seconds
      end
    end.new
  end

  def call_for(name, call_id)
    { 'type' => 'function_call', 'name' => name, 'call_id' => call_id, 'arguments' => '{}' }
  end
end

RSpec.configure { |c| c.include ToolCallExecutorHelpers }

describe Trading::ToolCallExecutor, 'Alpha Vantage throttling between consecutive calls' do
  it 'sleeps 1.25 seconds between consecutive Alpha Vantage calls' do
    sleeper = recording_sleeper
    executor = described_class.new(dispatcher: fake_dispatcher, sleeper: sleeper)
    calls = Array.new(3) { |i| call_for('alpha-vantage__time_series_daily', "av_#{i}") }

    executor.dispatch_all(calls, fake_state)

    expect(sleeper.sleeps).to eq([1.25, 1.25])
  end

  it 'does not sleep before the first Alpha Vantage call' do
    sleeper = recording_sleeper
    executor = described_class.new(dispatcher: fake_dispatcher, sleeper: sleeper)

    executor.dispatch_all([call_for('alpha-vantage__time_series_daily', 'av_1')], fake_state)

    expect(sleeper.sleeps).to be_empty
  end
end

describe Trading::ToolCallExecutor, 'non-Alpha Vantage tools' do
  it 'does not sleep when dispatching only non-Alpha Vantage tools' do
    sleeper = recording_sleeper
    executor = described_class.new(dispatcher: fake_dispatcher, sleeper: sleeper)
    calls = [
      call_for('hellthread__search_4chan', 'h_1'),
      call_for('unusual-whales__flow_alerts', 'u_1')
    ]

    executor.dispatch_all(calls, fake_state)

    expect(sleeper.sleeps).to be_empty
  end

  it 'still throttles Alpha Vantage when interleaved with other tools' do
    sleeper = recording_sleeper
    executor = described_class.new(dispatcher: fake_dispatcher, sleeper: sleeper)
    calls = [
      call_for('alpha-vantage__time_series_daily', 'av_1'),
      call_for('hellthread__search_4chan', 'h_1'),
      call_for('alpha-vantage__time_series_daily', 'av_2')
    ]

    executor.dispatch_all(calls, fake_state)

    expect(sleeper.sleeps).to eq([1.25])
  end
end

describe Trading::ToolCallExecutor, 'throttle persistence and defaults' do
  it 'tracks Alpha Vantage dispatches across multiple dispatch_all invocations' do
    sleeper = recording_sleeper
    executor = described_class.new(dispatcher: fake_dispatcher, sleeper: sleeper)

    executor.dispatch_all([call_for('alpha-vantage__time_series_daily', 'av_1')], fake_state)
    executor.dispatch_all([call_for('alpha-vantage__time_series_daily', 'av_2')], fake_state)

    expect(sleeper.sleeps).to eq([1.25])
  end

  it 'defaults to sleeping via Kernel' do
    executor = described_class.new(dispatcher: fake_dispatcher)
    allow(Kernel).to receive(:sleep)
    calls = Array.new(2) { |i| call_for('alpha-vantage__time_series_daily', "av_#{i}") }

    executor.dispatch_all(calls, fake_state)

    expect(Kernel).to have_received(:sleep).with(1.25).once
  end

  it 'exposes the throttle interval as a constant' do
    expect(described_class::ALPHA_VANTAGE_THROTTLE_SECONDS).to eq(1.25)
  end
end
