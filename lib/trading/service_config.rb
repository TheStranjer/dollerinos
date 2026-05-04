# frozen_string_literal: true

require_relative 'constants'

module Trading
  ServiceConfig = Struct.new(
    :liquidity_amount,
    :positions,
    :now,
    :xai_api_key,
    :hellthread_api_key,
    :unusual_whales_api_key,
    :max_iterations,
    :on_iteration,
    :mcp_client_factory,
    :xai_client_factory,
    :user_prompt,
    keyword_init: true
  ) do
    def normalized_positions
      positions.is_a?(Array) ? positions : [positions]
    end

    def normalized_liquidity
      value = Float(liquidity_amount, exception: false)
      return nil unless value&.positive?

      value
    end
  end
end
