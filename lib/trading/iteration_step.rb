# frozen_string_literal: true

require_relative 'constants'
require_relative 'quota_tracker'
require_relative 'xai_tool_specs'

module Trading
  IterationStep = Struct.new(:iteration, :max_iterations, :quota_tracker, keyword_init: true) do
    def phase
      return :force_trade_recs if iteration >= max_iterations
      return :open if tracker.all_met?

      :gather
    end

    def tools(mcp_tools_by_label)
      XaiToolSpecs.new(mcp_tools_by_label, quota_tracker: tracker).build(phase: phase)
    end

    def tool_choice
      case phase
      when :force_trade_recs then { type: 'function', name: Constants::FUNCTION_NAME }
      when :gather then 'required'
      else 'auto'
      end
    end

    private

    def tracker
      quota_tracker || QuotaTracker.new
    end
  end
end
