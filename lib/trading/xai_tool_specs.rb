# frozen_string_literal: true

require_relative 'constants'
require_relative 'quota_tracker'
require_relative 'tool_name_codec'
require_relative 'trade_function_schema'

module Trading
  # Builds the `tools` array passed to xAI based on the current loop phase:
  # - :force_trade_recs → only the trade_recommendations finalizer
  # - :gather → only research tools whose quota is not yet met (no finalizer)
  # - :open → all research tools plus the finalizer
  class XaiToolSpecs
    PHASES = %i[gather open force_trade_recs].freeze

    def initialize(mcp_tools_by_label, quota_tracker: QuotaTracker.new)
      @mcp_tools_by_label = mcp_tools_by_label
      @quota_tracker = quota_tracker
    end

    def build(phase:)
      case phase
      when :force_trade_recs then [trade_tool]
      when :gather then gather_tools
      when :open then open_tools
      else raise ArgumentError, "Unknown phase: #{phase.inspect}"
      end
    end

    def trade_tool
      {
        type: 'function',
        name: Constants::FUNCTION_NAME,
        description: 'Return recommended stock and options trades',
        parameters: TradeFunctionSchema.schema
      }
    end

    private

    def gather_tools
      tools = []
      tools << search_tool('x_search') unless @quota_tracker.met?(QuotaTracker::X_SEARCH)
      tools << search_tool('web_search') unless @quota_tracker.met?(QuotaTracker::WEB_SEARCH)
      tools.concat(mcp_function_tools(skip_met: true))
      tools
    end

    def open_tools
      [search_tool('x_search'), search_tool('web_search')] + mcp_function_tools(skip_met: false) + [trade_tool]
    end

    def search_tool(type)
      { type: type }
    end

    def mcp_function_tools(skip_met:)
      @mcp_tools_by_label.flat_map do |label, tools|
        next [] if skip_met && @quota_tracker.met?(label)

        tools.map { |tool| mcp_tool_spec(label, tool) }
      end
    end

    def mcp_tool_spec(label, tool)
      {
        type: 'function',
        name: ToolNameCodec.encode(label, tool.name),
        description: tool.description.to_s,
        parameters: schema_or_default(tool.input_schema)
      }
    end

    def schema_or_default(schema)
      schema.is_a?(Hash) ? schema : { type: 'object', properties: {} }
    end
  end
end
