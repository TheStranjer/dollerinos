#!/usr/bin/env ruby

require "bundler/setup" if File.exist?(File.expand_path("../../Gemfile", __FILE__))
require_relative "../lib/grok_trade_service"
require "lipgloss"

class GrokTradeRecommender
  def initialize(liquidity_amount)
    @liquidity_amount = liquidity_amount
    setup_styles
  end

  def run
    service = Trading::GrokTradeService.new(liquidity_amount: @liquidity_amount)
    result = service.call

    if result.success?
      display_trades(result.trades)
      exit(0)
    else
      display_error(result.error_message)
      exit(1)
    end
  end

  private

  def setup_styles
    @header_style = Lipgloss::Style.new
      .bold(true)
      .foreground("#00D7FF")

    @stocks_title_style = Lipgloss::Style.new
      .bold(true)
      .foreground("#00FF00")

    @options_title_style = Lipgloss::Style.new
      .bold(true)
      .foreground("#FFFF00")

    @stock_symbol_style = Lipgloss::Style.new
      .foreground("#00D7FF")

    @option_symbol_style = Lipgloss::Style.new
      .foreground("#FF00FF")

    @error_style = Lipgloss::Style.new
      .bold(true)
      .foreground("#FF0000")

    @info_label_style = Lipgloss::Style.new
      .foreground("#AAAAAA")
  end

  def display_trades(trades)
    puts
    puts @header_style.render("🚀 Grok Trade Recommendations")
    puts
    puts "Total Recommendations: #{trades.length}"
    puts "=" * 80
    puts

    stocks = trades.select(&:stock?)
    options = trades.select(&:option?)

    display_stocks(stocks) if stocks.any?
    display_options(options) if options.any?
  end

  def display_stocks(stocks)
    puts @stocks_title_style.render("📈 STOCKS (#{stocks.length})")
    puts

    stocks.each_with_index do |trade, idx|
      display_stock_card(trade, idx + 1)
    end

    puts
  end

  def display_stock_card(trade, number)
    puts "  #{@stock_symbol_style.render("#{number}. #{trade.symbol}")}"

    price_range = "#{format_price(trade.min_price)} - #{format_price(trade.max_price)}"
    confidence_bar = confidence_indicator(trade.confidence)

    puts "     #{@info_label_style.render("Price Range:")} #{price_range}"
    puts "     #{@info_label_style.render("Confidence:")}  #{confidence_bar} (#{trade.confidence}%)"
    puts "     #{@info_label_style.render("Thesis:")}      #{trade.reasoning}"
    puts
  end

  def display_options(options)
    puts @options_title_style.render("📊 OPTIONS (#{options.length})")
    puts

    options.each_with_index do |trade, idx|
      display_option_card(trade, idx + 1)
    end

    puts
  end

  def display_option_card(trade, number)
    position = trade.position_type&.upcase || "?"
    option_type = trade.option_type&.upcase || "?"

    puts "  #{@option_symbol_style.render("#{number}. #{trade.symbol} #{option_type} - #{position}")}"

    strike = trade.strike_price ? format_price(trade.strike_price) : "N/A"
    expiry = if trade.expiration_date_min && trade.expiration_date_max
      "#{trade.expiration_date_min} - #{trade.expiration_date_max}"
    else
      "N/A"
    end

    premium_range = "#{format_price(trade.min_price)} - #{format_price(trade.max_price)}"
    confidence_bar = confidence_indicator(trade.confidence)

    puts "     #{@info_label_style.render("Strike:")}      #{strike}"
    puts "     #{@info_label_style.render("Expiration:")}  #{expiry}"
    puts "     #{@info_label_style.render("Premium:")}     #{premium_range}"
    puts "     #{@info_label_style.render("Confidence:")}  #{confidence_bar} (#{trade.confidence}%)"
    puts "     #{@info_label_style.render("Thesis:")}      #{trade.reasoning}"
    puts
  end

  def format_price(price)
    return "N/A" if price.nil?

    if price >= 1
      "$#{price.round(2)}"
    else
      "$#{price.round(4)}"
    end
  end

  def confidence_indicator(confidence)
    filled = (confidence / 10).floor
    empty = 10 - filled

    green = Lipgloss::Style.new.foreground("#00FF00")
    gray = Lipgloss::Style.new.foreground("#666666")

    bar = green.render("█" * filled)
    bar += gray.render("░" * empty)

    bar
  end

  def display_error(message)
    puts
    puts @error_style.render("❌ Error")
    puts
    puts message
    puts
  end
end

if __FILE__ == $0
  # Main execution
  if ARGV.length != 1
    puts "Usage: #{$0} <liquidity_amount>"
    puts "Example: #{$0} 10000"
    exit(1)
  end

  liquidity = ARGV[0]

  begin
    amount = Float(liquidity)
    raise "Liquidity amount must be positive" if amount <= 0

    recommender = GrokTradeRecommender.new(amount)
    recommender.run
  rescue ArgumentError, StandardError => e
    puts "Error: #{e.message}"
    exit(1)
  end
end
