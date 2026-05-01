# frozen_string_literal: true

require_relative 'structs'

module Trading
  # Lists tools exposed by each MCP server, surfacing transport errors as ServiceError.
  class McpToolLister
    def initialize(mcp_clients)
      @mcp_clients = mcp_clients
    end

    def list
      @mcp_clients.transform_values { |client| safe_tools(client) }
    end

    private

    def safe_tools(client)
      client.tools
    rescue StandardError => e
      raise ServiceError, "Failed to list tools from MCP server: #{e.message}"
    end
  end
end
