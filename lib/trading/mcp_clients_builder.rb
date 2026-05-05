# frozen_string_literal: true

require_relative 'constants'
require_relative 'mcp_client_factory'
require_relative 'structs'

module Trading
  # Builds the per-server MCP clients used during a trade-recommendation run.
  class McpClientsBuilder
    SERVERS = [
      { label: Constants::HELLTHREAD_LABEL, url: Constants::HELLTHREAD_URL,
        key_method: :hellthread_api_key, auth: :bearer },
      { label: Constants::UNUSUAL_WHALES_LABEL, url: Constants::UNUSUAL_WHALES_URL,
        key_method: :unusual_whales_api_key, auth: :bearer },
      { label: Constants::ALPHA_VANTAGE_LABEL, url: Constants::ALPHA_VANTAGE_URL,
        key_method: :alpha_vantage_api_key, auth: :query }
    ].freeze

    def initialize(config)
      @config = config
    end

    def build
      SERVERS.to_h { |server| [server[:label], build_one(server)] }
    end

    private

    def build_one(server)
      factory.call(
        label: server[:label],
        url: server[:url],
        api_key: @config.public_send(server[:key_method]),
        auth: server[:auth]
      )
    end

    def factory
      @config.mcp_client_factory || McpClientFactory.method(:build)
    end
  end
end
