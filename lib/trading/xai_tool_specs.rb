# frozen_string_literal: true

require_relative 'constants'
require_relative 'tool_name_codec'
require_relative 'trade_function_schema'

module Trading
  # Builds the `tools` array passed to xAI: built-in search tools, MCP-namespaced
  # function tools, and the trade_recommendations finalizer.
  class XaiToolSpecs
    def initialize(mcp_tools_by_label)
      @mcp_tools_by_label = mcp_tools_by_label
    end

    def build(force_only_trade_recs:)
      return [trade_tool] if force_only_trade_recs

      [search_tool('x_search'), search_tool('web_search')] + mcp_function_tools + [trade_tool]
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

    def search_tool(type)
      { type: type }
    end

    def mcp_function_tools
      @mcp_tools_by_label.flat_map do |label, tools|
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
