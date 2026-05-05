# frozen_string_literal: true

module Trading
  # Duck-typed listener interface used by LoopRunner and ToolCallExecutor to
  # surface iteration progress (header/tools, model output, individual tool
  # call dispatches) to a UI layer in real time. The default Null implementation
  # silently ignores every event.
  module IterationListener
    # No-op listener used as the default when no UI is wired up. Accepts every
    # event and silently discards it so LoopRunner can dispatch unconditionally.
    class Null
      def iteration_started(**); end
      def model_output(**); end
      def tool_call_started(**); end
      def tool_call_completed(**); end
      def iteration_finished(**); end
    end
  end
end
