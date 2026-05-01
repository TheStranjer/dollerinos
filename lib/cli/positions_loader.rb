# frozen_string_literal: true

require 'json'
require_relative '../grok_trade_service'

module Cli
  # Reads a JSON positions file and converts entries into Trading::Position structs.
  class PositionsLoader
    def initialize(path)
      @path = path
    end

    def load
      raise "Positions file not found: #{@path}" unless File.exist?(@path)

      parsed = parse_json(File.read(@path))
      raise 'Positions file must contain a JSON array' unless parsed.is_a?(Array)

      parsed.map { |data| build_position(data) }
    end

    private

    def parse_json(json_data)
      JSON.parse(json_data)
    rescue JSON::ParserError => e
      raise "Invalid JSON in positions file: #{e.message}"
    end

    def build_position(data)
      Trading::GrokTradeService::Position.new(**position_attributes(data))
    end

    def position_attributes(data)
      {
        type: data['type']&.downcase,
        symbol: data['symbol']&.upcase&.strip,
        quantity: data['quantity'],
        position_type: data['position_type']&.downcase,
        strike_price: data['strike_price'],
        expiration_date: data['expiration_date'],
        option_type: data['option_type']&.downcase
      }
    end
  end
end
