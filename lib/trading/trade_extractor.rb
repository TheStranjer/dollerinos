# frozen_string_literal: true

require 'json'
require_relative 'constants'
require_relative 'structs'

module Trading
  # Parses the trade_recommendations function call arguments and returns the
  # validated Trade structs.
  class TradeExtractor
    def extract(function_call)
      arguments = JSON.parse(function_call.fetch('arguments'))
      trades_data = arguments['trades']
      raise ServiceError, invalid_args_message unless trades_data.is_a?(Array)

      trades = build_trades(trades_data)
      raise ServiceError, 'xAI returned no valid trade recommendations.' if trades.empty?

      trades
    end

    private

    def invalid_args_message
      "xAI returned invalid #{Constants::FUNCTION_NAME} arguments."
    end

    def build_trades(trades_data)
      trades_data.filter_map do |trade_data|
        next unless trade_data.is_a?(Hash)

        trade = TradeBuilder.build(trade_data)
        trade if trade&.valid?
      end
    end
  end

  # Maps a single hash from xAI into a Trade struct with normalized fields.
  module TradeBuilder
    module_function

    def build(data)
      Trade.new(**trade_attributes(data))
    end

    def trade_attributes(data)
      basic_attributes(data).merge(option_attributes(data))
    end

    def basic_attributes(data)
      {
        type: data['type']&.downcase,
        symbol: data['symbol']&.upcase&.strip,
        min_price: float_or_zero(data['min_price']),
        max_price: float_or_zero(data['max_price']),
        confidence: integer_or_zero(data['confidence']),
        reasoning: data['reasoning']&.to_s&.strip
      }
    end

    def option_attributes(data)
      {
        strike_price: Float(data['strike_price'], exception: false),
        expiration_date_min: data['expiration_date_min'],
        expiration_date_max: data['expiration_date_max'],
        option_type: data['option_type']&.downcase,
        position_type: data['position_type']&.downcase
      }
    end

    def float_or_zero(value)
      Float(value, exception: false) || 0
    end

    def integer_or_zero(value)
      Integer(value, exception: false) || 0
    end
  end
end
