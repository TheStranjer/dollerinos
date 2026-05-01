# frozen_string_literal: true

require 'json'
require_relative 'tool_name_codec'
require_relative 'mcp_response_formatter'

module Trading
  # Routes a single function_call from xAI to the appropriate MCP server and tool,
  # returning the result text (or a JSON error payload).
  class McpToolDispatcher
    def initialize(mcp_clients:, mcp_tools_by_label:)
      @mcp_clients = mcp_clients
      @mcp_tools_by_label = mcp_tools_by_label
    end

    def dispatch(function_call)
      name = function_call['name'].to_s
      label, tool_name = ToolNameCodec.decode(name)
      return unknown_tool_error(name) unless label && @mcp_clients.key?(label)

      tool = find_tool(label, tool_name)
      return tool_not_found_error(label, tool_name) unless tool

      invoke(label, tool, function_call)
    end

    private

    def find_tool(label, tool_name)
      tools = @mcp_tools_by_label[label] || []
      tools.find { |t| t.name == tool_name }
    end

    def invoke(label, tool, function_call)
      arguments = parse_arguments(function_call['arguments'])
      response = @mcp_clients[label].call_tool(tool: tool, arguments: arguments)
      McpResponseFormatter.format(response)
    rescue StandardError => e
      JSON.generate({ error: "Tool execution failed: #{e.message}" })
    end

    def parse_arguments(raw)
      return {} if raw.nil? || raw == ''

      parsed = JSON.parse(raw)
      parsed.is_a?(Hash) ? parsed : {}
    rescue JSON::ParserError
      {}
    end

    def unknown_tool_error(name)
      JSON.generate({ error: "Unknown tool '#{name}'." })
    end

    def tool_not_found_error(label, tool_name)
      JSON.generate({ error: "Tool '#{tool_name}' not found on '#{label}'." })
    end
  end
end
