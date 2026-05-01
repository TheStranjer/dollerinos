# frozen_string_literal: true

require 'mcp'
require 'mcp/client/http'

module Trading
  # Default factory for building authenticated MCP::Client instances over HTTP.
  module McpClientFactory
    module_function

    def build(label:, url:, api_key:)
      _ = label
      headers = { 'Authorization' => "Bearer #{api_key}" }
      transport = MCP::Client::HTTP.new(url: url, headers: headers)
      MCP::Client.new(transport: transport)
    end
  end
end
