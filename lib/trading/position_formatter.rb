# frozen_string_literal: true

module Trading
  # Renders a Position into the bullet-line format used inside the user prompt.
  module PositionFormatter
    module_function

    def format(position)
      case position.type&.downcase
      when 'stock' then format_stock(position)
      when 'option' then format_option(position)
      else ''
      end
    end

    def format_stock(position)
      "- #{position.quantity} shares of #{position.symbol} (#{position.position_type})\n"
    end

    def format_option(position)
      strike = position.strike_price&.round(2)
      "- #{position.quantity} contracts #{position.symbol} #{strike} #{position.option_type}, " \
        "expiring #{position.expiration_date} (#{position.position_type})\n"
    end
  end
end
