# frozen_string_literal: true

require 'active_support/core_ext/object/blank'

module Trading
  Position = Struct.new(
    :type,
    :symbol,
    :quantity,
    :position_type,
    :strike_price,
    :expiration_date,
    :option_type,
    keyword_init: true
  )

  Trade = Struct.new(
    :type,
    :symbol,
    :min_price,
    :max_price,
    :confidence,
    :reasoning,
    :strike_price,
    :expiration_date_min,
    :expiration_date_max,
    :option_type,
    :position_type,
    keyword_init: true
  ) do
    def valid?
      valid_type? && valid_symbol_and_prices? && valid_confidence_and_reasoning?
    end

    def valid_type?
      type.in?(%w[stock option])
    end

    def valid_symbol_and_prices?
      symbol.present? && min_price.positive? && max_price >= min_price
    end

    def valid_confidence_and_reasoning?
      confidence.between?(0, 100) && reasoning.present?
    end

    def stock?
      type == 'stock'
    end

    def option?
      type == 'option'
    end
  end

  Result = Struct.new(
    :trades, :error_message, :usage, :duration_ms,
    :iterations, :reconsideration_iterations, :sentiment_analyses,
    keyword_init: true
  ) do
    def success?
      error_message.blank?
    end
  end

  SentimentAnalysis = Struct.new(:trade, :text, keyword_init: true)

  ServiceError = Class.new(StandardError)
end
