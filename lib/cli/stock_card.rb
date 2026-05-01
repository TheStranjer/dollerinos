# frozen_string_literal: true

require_relative 'format_helpers'

module Cli
  # Renders a single stock recommendation card.
  class StockCard
    def initialize(palette)
      @palette = palette
    end

    def render(trade, number)
      puts "  #{title(trade, number)} - #{action(trade)}"
      puts "     #{label('Price Range:')} #{price_range(trade)}"
      puts "     #{label('Confidence:')}  #{confidence(trade)} (#{trade.confidence}%)"
      puts "     #{label('Thesis:')}      #{trade.reasoning}"
      puts
    end

    private

    def title(trade, number)
      @palette[:stock_symbol].render("#{number}. #{trade.symbol}")
    end

    def action(trade)
      label_text = trade.position_type&.upcase || '?'
      style_for(trade).render(label_text)
    end

    def style_for(trade)
      trade.position_type&.downcase == 'buy' ? @palette[:buy_action] : @palette[:sell_action]
    end

    def label(text)
      @palette[:info_label].render(text)
    end

    def price_range(trade)
      "#{FormatHelpers.format_price(trade.min_price)} - #{FormatHelpers.format_price(trade.max_price)}"
    end

    def confidence(trade)
      FormatHelpers.confidence_indicator(trade.confidence)
    end
  end
end
