#!/usr/bin/env ruby

require "bundler/setup" if File.exist?(File.expand_path("../../Gemfile", __FILE__))
require_relative "../lib/grok_trade_service"
require "lipgloss"
require "json"

class GrokTradeRecommender
  def initialize(liquidity_amount, positions_file: nil)
    @liquidity_amount = liquidity_amount
    @positions_file = positions_file
    setup_styles
  end

  def run
    positions = load_positions if @positions_file
    service = Trading::GrokTradeService.new(liquidity_amount: @liquidity_amount, positions: positions || [])
    result = service.call

    if result.success?
      display_trades(result.trades, result.usage)
      exit(0)
    else
      display_error(result.error_message)
      exit(1)
    end
  end

  private

  def load_positions
    unless File.exist?(@positions_file)
      raise "Positions file not found: #{@positions_file}"
    end

    json_data = File.read(@positions_file)
    positions_data = JSON.parse(json_data)

    unless positions_data.is_a?(Array)
      raise "Positions file must contain a JSON array"
    end

    positions_data.map { |pos_data| build_position(pos_data) }
  rescue JSON::ParserError => e
    raise "Invalid JSON in positions file: #{e.message}"
  end

  def build_position(data)
    Trading::GrokTradeService::Position.new(
      type: data["type"]&.downcase,
      symbol: data["symbol"]&.upcase&.strip,
      quantity: data["quantity"],
      position_type: data["position_type"]&.downcase,
      strike_price: data["strike_price"],
      expiration_date: data["expiration_date"],
      option_type: data["option_type"]&.downcase
    )
  end

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

  def display_trades(trades, usage = {})
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

    display_token_usage(usage) if usage.any?
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

  def display_token_usage(usage)
    puts
    puts @info_label_style.render("📊 Token Usage")
    puts "=" * 80

    input_tokens = usage["input_tokens"] || 0
    output_tokens = usage["output_tokens"] || 0
    reasoning_tokens = usage["reasoning_tokens"] || 0
    total_tokens = usage["total_tokens"] || (input_tokens + output_tokens + reasoning_tokens)

    puts "  Input Tokens:     #{format_number(input_tokens)}"
    puts "  Output Tokens:    #{format_number(output_tokens)}"
    if reasoning_tokens > 0
      puts "  Reasoning Tokens: #{format_number(reasoning_tokens)}"
    end
    puts "  Total Tokens:     #{format_number(total_tokens)}"
    puts
  end

  def format_number(num)
    num.to_s.reverse.scan(/\d{1,3}/).join(",").reverse
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
  if ARGV.length < 1 || ARGV.length > 2
    puts "Usage: #{$0} <liquidity_amount> [positions_file]"
    puts
    puts "Arguments:"
    puts "  liquidity_amount  - Amount of capital available for trading (required)"
    puts "  positions_file    - Path to JSON file with current positions (optional)"
    puts
    puts "Examples:"
    puts "  #{$0} 10000"
    puts "  #{$0} 10000 positions.json"
    exit(1)
  end

  liquidity = ARGV[0]
  positions_file = ARGV[1]

  begin
    amount = Float(liquidity)
    raise "Liquidity amount must be positive" if amount <= 0

    recommender = GrokTradeRecommender.new(amount, positions_file: positions_file)
    recommender.run
  rescue ArgumentError, StandardError => e
    puts "Error: #{e.message}"
    exit(1)
  end
end
