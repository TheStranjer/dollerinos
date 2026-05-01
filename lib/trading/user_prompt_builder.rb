# frozen_string_literal: true

require 'active_support/core_ext/string'
require_relative 'position_formatter'

module Trading
  # Builds the user-facing prompt: liquidity context plus optional positions block.
  class UserPromptBuilder
    BASE_TEMPLATE = <<~PROMPT
      I have $%<amount>s available for trading. Please identify and recommend
      promising stock and options trades I should consider. Research current market trends, unusual
      activity (especially from Unusual Whales), relevant news and discussions, and technical opportunities.

      For each recommendation, provide:
      - Whether it's a stock or options trade
      - The stock symbol/ticker
      - Price range estimates (for stocks) or strike price, expiration window, and position type (for options)
      - Your confidence level (0-100)
      - Clear reasoning for the recommendation

      Ensure recommendations are appropriately sized for a $%<amount>s account.
    PROMPT

    CLOSING_TEXT = 'Please consider recommendations for managing, scaling, or closing these positions as appropriate.'

    def initialize(liquidity_amount:, positions:)
      @liquidity_amount = liquidity_amount
      @positions = positions
    end

    def build
      base = base_text
      return base if @positions.empty?

      "#{base}\n\nMy current positions:\n#{positions_text}\n#{CLOSING_TEXT}"
    end

    private

    def base_text
      format(BASE_TEMPLATE, amount: @liquidity_amount.round(2)).squish
    end

    def positions_text
      @positions.map { |position| PositionFormatter.format(position) }.join
    end
  end
end
