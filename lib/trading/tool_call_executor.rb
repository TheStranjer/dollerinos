# frozen_string_literal: true

module Trading
  # Iterates over a turn's non-trade function calls, dispatching each via the
  # supplied dispatcher and recording the function_call_output back into state.
  class ToolCallExecutor
    def initialize(dispatcher:)
      @dispatcher = dispatcher
    end

    def dispatch_all(function_calls, state)
      function_calls.map { |fc| dispatch_one(fc, state) }
    end

    private

    def dispatch_one(function_call, state)
      result_text = @dispatcher.dispatch(function_call)
      call_id = function_call['call_id'] || function_call['id']
      state.append_function_output(call_id, result_text)
      result_summary(function_call, call_id, result_text)
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
