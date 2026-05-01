# frozen_string_literal: true

require_relative 'constants'
require_relative 'mcp_client_factory'
require_relative 'structs'

module Trading
  # Builds the per-server MCP clients used during a trade-recommendation run.
  class McpClientsBuilder
    SERVERS = [
      [Constants::HELLTHREAD_LABEL, Constants::HELLTHREAD_URL, :hellthread_api_key],
      [Constants::UNUSUAL_WHALES_LABEL, Constants::UNUSUAL_WHALES_URL, :unusual_whales_api_key]
    ].freeze

    def initialize(config)
      @config = config
    end

    def build
      SERVERS.to_h { |label, url, key_method| [label, build_one(label, url, key_method)] }
    end

    private

    def build_one(label, url, key_method)
      factory.call(label: label, url: url, api_key: @config.public_send(key_method))
    end

    def factory
      @config.mcp_client_factory || McpClientFactory.method(:build)
    end
  end
end
