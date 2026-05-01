# frozen_string_literal: true

require 'active_support/core_ext/object/blank'

module Trading
  # Validates a ServiceConfig and returns the first error message it finds, or nil.
  class ConfigValidator
    def initialize(config)
      @config = config
    end

    def validate
      liquidity_error || keys_error || iterations_error
    end

    private

    attr_reader :config

    def liquidity_error
      return if config.normalized_liquidity

      'Liquidity amount must be a positive number.'
    end

    def keys_error
      return 'XAI_API_KEY is not configured.' if config.xai_api_key.blank?
      return 'HELLTHREAD_API_KEY is not configured.' if config.hellthread_api_key.blank?
      return 'UNUSUAL_WHALES_API_KEY is not configured.' if config.unusual_whales_api_key.blank?

      nil
    end

    def iterations_error
      return if config.max_iterations.to_i >= 1

      'max_iterations must be at least 1.'
    end
  end
end
