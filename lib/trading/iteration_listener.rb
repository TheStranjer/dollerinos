# frozen_string_literal: true

module Trading
  # Duck-typed listener interface used by LoopRunner, ToolCallExecutor, and the
  # sentiment/reconsideration phases to surface progress (header/tools, model
  # output, individual tool call dispatches, sentiment summaries) to a UI layer
  # in real time. Listeners can implement only the events they care about.
  module IterationListener
    EVENTS = %i[
      iteration_started model_output tool_call_started tool_call_completed iteration_finished
      sentiment_started sentiment_completed
      reconsideration_started
      reconsideration_iteration_started reconsideration_model_output
      reconsideration_tool_call_started reconsideration_tool_call_completed
      reconsideration_iteration_finished
    ].freeze

    # No-op listener used as the default when no UI is wired up. Silently
    # swallows every known event so callers can dispatch unconditionally.
    class Null
      EVENTS.each { |event| define_method(event) { |**| } }
    end

    # Adapter that prefixes every emitted event name before forwarding to an
    # inner listener. Used by LoopRunner so the same dispatcher/executor code
    # can fire `iteration_started` for the initial loop and
    # `reconsideration_iteration_started` for the reconsideration loop without
    # branching at every call site.
    class Prefixed
      FORWARDED = %i[tool_call_started tool_call_completed].freeze

      def initialize(inner, prefix: '')
        @inner = inner
        @prefix = prefix.to_s
      end

      FORWARDED.each do |event|
        define_method(event) do |**payload|
          method_name = :"#{@prefix}#{event}"
          @inner.public_send(method_name, **payload) if @inner.respond_to?(method_name)
        end
      end
    end
  end
end
