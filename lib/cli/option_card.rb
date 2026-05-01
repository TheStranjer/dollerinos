# frozen_string_literal: true

require_relative 'format_helpers'

module Cli
  # Renders a single options recommendation card.
  class OptionCard
    def initialize(palette)
      @palette = palette
    end

    def render(trade, number)
      puts "  #{title(trade, number)} - #{action(trade)}"
      details(trade).each { |line| puts "     #{line}" }
      puts
    end

    private

    def details(trade)
      [
        "#{label('Strike:')}      #{strike(trade)}",
        "#{label('Expiration:')}  #{expiration(trade)}",
        "#{label('Premium:')}     #{premium(trade)}",
        "#{label('Confidence:')}  #{confidence(trade)} (#{trade.confidence}%)",
        "#{label('Thesis:')}      #{trade.reasoning}"
      ]
    end

    def title(trade, number)
      option_type = trade.option_type&.upcase || '?'
      @palette[:option_symbol].render("#{number}. #{trade.symbol} #{option_type}")
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

    def strike(trade)
      trade.strike_price ? FormatHelpers.format_price(trade.strike_price) : 'N/A'
    end

    def expiration(trade)
      return 'N/A' unless trade.expiration_date_min && trade.expiration_date_max

      "#{trade.expiration_date_min} - #{trade.expiration_date_max}"
    end

    def premium(trade)
      "#{FormatHelpers.format_price(trade.min_price)} - #{FormatHelpers.format_price(trade.max_price)}"
    end

    def confidence(trade)
      FormatHelpers.confidence_indicator(trade.confidence)
    end
  end
end
