# frozen_string_literal: true

require_relative 'option_card'
require_relative 'stock_card'
require_relative 'token_usage_display'

module Cli
  # Renders the full set of recommendations to stdout: stocks, options,
  # sentiment summaries, and usage.
  class TradeDisplay
    def initialize(palette)
      @palette = palette
    end

    def render(trades, usage = nil, duration_ms = nil, sentiment_analyses = nil)
      usage ||= {}
      duration_ms = duration_ms.to_i
      sentiment_analyses ||= []
      print_header(trades.size)
      render_groups(trades)
      render_sentiments(sentiment_analyses) if sentiment_analyses.any?
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

    def render_sentiments(sentiment_analyses)
      puts @palette[:options_title].render("🧠 SENTIMENT ANALYSIS (#{sentiment_analyses.size})")
      puts
      sentiment_analyses.each_with_index { |analysis, idx| render_sentiment(analysis, idx + 1) }
      puts
    end

    def render_sentiment(analysis, index)
      trade = analysis.trade
      puts "#{@palette[:info_label].render("#{index}.")} #{sentiment_label(trade)}"
      analysis.text.to_s.each_line { |line| puts "   #{line.chomp}" }
      puts
    end

    def sentiment_label(trade)
      symbol_style = trade.option? ? @palette[:option_symbol] : @palette[:stock_symbol]
      type_style = trade.option? ? @palette[:options_title] : @palette[:stocks_title]
      type_text = trade.option? ? "option/#{trade.option_type&.upcase || '?'}" : 'stock'
      "#{type_style.render(type_text)} #{symbol_style.render(trade.symbol.to_s)}"
    end
  end
end
