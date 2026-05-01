# frozen_string_literal: true

require_relative 'option_card'
require_relative 'stock_card'
require_relative 'token_usage_display'

module Cli
  # Renders the full set of recommendations to stdout: stocks, options, usage.
  class TradeDisplay
    def initialize(palette)
      @palette = palette
    end

    def render(trades, usage = nil, duration_ms = nil)
      usage ||= {}
      duration_ms = duration_ms.to_i
      print_header(trades.size)
      render_groups(trades)
      render_usage(usage, duration_ms) if usage.any? || duration_ms.positive?
    end

    private

    def render_groups(trades)
      stocks = trades.select(&:stock?)
      options = trades.select(&:option?)
      render_stocks(stocks) if stocks.any?
      render_options(options) if options.any?
    end

    def render_usage(usage, duration_ms)
      TokenUsageDisplay.new(@palette).render(usage, duration_ms)
    end

    def print_header(count)
      puts
      puts @palette[:header].render('🚀 Grok Trade Recommendations')
      puts
      puts "Total Recommendations: #{count}"
      puts '=' * 80
      puts
    end

    def render_stocks(stocks)
      puts @palette[:stocks_title].render("📈 STOCKS (#{stocks.size})")
      puts
      stocks.each_with_index { |trade, idx| StockCard.new(@palette).render(trade, idx + 1) }
      puts
    end

    def render_options(options)
      puts @palette[:options_title].render("📊 OPTIONS (#{options.size})")
      puts
      options.each_with_index { |trade, idx| OptionCard.new(@palette).render(trade, idx + 1) }
      puts
    end
  end
end
