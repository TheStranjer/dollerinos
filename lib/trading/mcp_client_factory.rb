# frozen_string_literal: true

require 'mcp'
require 'mcp/client/http'

module Trading
  # Default factory for building authenticated MCP::Client instances over HTTP.
  # Two auth styles are supported:
  # - :bearer (default) puts the API key in an Authorization header
  # - :query takes a URL containing a `%<api_key>s` placeholder and substitutes the key in
  module McpClientFactory
    module_function

    def build(label:, url:, api_key:, auth: :bearer)
      _ = label
      transport = transport_for(url: url, api_key: api_key, auth: auth)
      MCP::Client.new(transport: transport)
    end

    def transport_for(url:, api_key:, auth:)
      case auth
      when :query
        MCP::Client::HTTP.new(url: format(url, api_key: api_key))
      else
        MCP::Client::HTTP.new(url: url, headers: { 'Authorization' => "Bearer #{api_key}" })
      end
    end
  end
end
