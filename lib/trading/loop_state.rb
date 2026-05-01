# frozen_string_literal: true

require_relative 'system_prompt'

module Trading
  # Mutable state for the agentic loop: tracks iteration count and the running
  # input array sent to xAI on each turn.
  class LoopState
    attr_reader :iteration, :input

    def initialize(initial_input:)
      @input = initial_input.dup
      @iteration = 0
    end

    def begin_iteration(max_iterations)
      @iteration += 1
      @input[0] = { role: 'system', content: SystemPrompt.for_iteration(@iteration, max_iterations) }
    end

    def append_outputs(output_items)
      @input.concat(output_items)
    end

    def append_function_output(call_id, text)
      @input << { type: 'function_call_output', call_id: call_id, output: text }
    end

    def append_user_reminder(message)
      @input << { role: 'user', content: message }
    end
  end
end
