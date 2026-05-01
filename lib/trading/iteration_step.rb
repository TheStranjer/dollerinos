# frozen_string_literal: true

require_relative 'constants'
require_relative 'xai_tool_specs'

module Trading
  IterationStep = Struct.new(:iteration, :max_iterations, keyword_init: true) do
    def last?
      iteration == max_iterations
    end

    def tools(mcp_tools_by_label)
      XaiToolSpecs.new(mcp_tools_by_label).build(force_only_trade_recs: last?)
    end

    def tool_choice
      return { type: 'function', name: Constants::FUNCTION_NAME } if last?

      'auto'
    end
  end
end
