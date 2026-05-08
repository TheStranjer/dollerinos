# frozen_string_literal: true

require_relative '../grok_trade_service'
require_relative 'error_display'
require_relative 'iteration_display'
require_relative 'positions_loader'
require_relative 'styles'
require_relative 'trade_display'

module Cli
  # Orchestrator for the recommender CLI: loads positions, drives the service,
  # and renders the result.
  class Recommender
    def initialize(liquidity_amount, positions_file: nil, user_prompt: nil)
      @liquidity_amount = liquidity_amount
      @positions_file = positions_file
      @user_prompt = user_prompt
      @palette = Styles.palette
    end

    def run
      result = Trading::GrokTradeService.new(**service_options).call
      result.success? ? render_success(result) : render_failure(result)
      result.success? ? 0 : 1
    end

    private

    def service_options
      {
        liquidity_amount: @liquidity_amount,
        positions: load_positions,
        on_iteration: iteration_display,
        user_prompt: @user_prompt
      }
    end

    def load_positions
      return [] unless @positions_file

      PositionsLoader.new(@positions_file).load
    end

    def iteration_display
      @iteration_display ||= IterationDisplay.new(@palette)
    end

    def render_success(result)
      TradeDisplay.new(@palette).render(
        result.trades, result.usage, result.duration_ms, result.sentiment_analyses
      )
    end

    def render_failure(result)
      ErrorDisplay.new(@palette).render(result.error_message)
    end
  end
end
