# frozen_string_literal: true

require_relative 'constants'
require_relative 'iteration_listener'
require_relative 'tool_name_codec'

module Trading
  # Iterates over a turn's non-trade function calls, dispatching each via the
  # supplied dispatcher and recording the function_call_output back into state.
  class ToolCallExecutor
    # Alpha Vantage's free tier asks callers to space requests at least one
    # second apart; we use a small safety margin to stay under the limit.
    ALPHA_VANTAGE_THROTTLE_SECONDS = 1.25

    def initialize(dispatcher:, sleeper: Kernel, listener: IterationListener::Null.new)
      @dispatcher = dispatcher
      @sleeper = sleeper
      @listener = listener
      @alpha_vantage_dispatched = false
    end

    def dispatch_all(function_calls, state)
      function_calls.map { |fc| dispatch_one(fc, state) }
    end

    private

    def dispatch_one(function_call, state)
      @listener.tool_call_started(function_call: function_call)
      throttle_alpha_vantage(function_call)
      result_text = @dispatcher.dispatch(function_call)
      call_id = function_call['call_id'] || function_call['id']
      state.append_function_output(call_id, result_text)
      summary = result_summary(function_call, call_id, result_text)
      @listener.tool_call_completed(function_call: function_call, result: summary)
      summary
    end

    def throttle_alpha_vantage(function_call)
      return unless alpha_vantage?(function_call)

      @sleeper.sleep(ALPHA_VANTAGE_THROTTLE_SECONDS) if @alpha_vantage_dispatched
      @alpha_vantage_dispatched = true
    end

    def alpha_vantage?(function_call)
      label, _tool = ToolNameCodec.decode(function_call['name'].to_s)
      label == Constants::ALPHA_VANTAGE_LABEL
    end

    def result_summary(function_call, call_id, result_text)
      {
        name: function_call['name'],
        arguments: function_call['arguments'],
        call_id: call_id,
        result: result_text
      }
    end
  end
end
