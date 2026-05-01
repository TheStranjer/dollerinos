# frozen_string_literal: true

require 'lipgloss'

module Cli
  # Number/price/duration formatting helpers used by display classes.
  module FormatHelpers
    BAR_LENGTH = 10

    module_function

    def format_price(price)
      return 'N/A' if price.nil?
      return "$#{price.round(2)}" if price >= 1

      "$#{price.round(4)}"
    end

    def format_number(number)
      number.to_s.reverse.scan(/\d{1,3}/).join(',').reverse
    end

    def format_duration(duration_ms)
      total_seconds = duration_ms / 1000
      parts = duration_parts(total_seconds)
      parts << "#{total_seconds}s" if parts.empty?
      parts.join(' ')
    end

    def duration_parts(total_seconds)
      hours, rest = total_seconds.divmod(3600)
      minutes, seconds = rest.divmod(60)
      [
        ("#{hours}hr" if hours.positive?),
        ("#{minutes}min" if minutes.positive?),
        ("#{seconds}s" if seconds.positive?)
      ].compact
    end

    def confidence_indicator(confidence)
      filled = (confidence / BAR_LENGTH).floor
      empty = BAR_LENGTH - filled
      Lipgloss::Style.new.foreground('#00FF00').render('█' * filled) +
        Lipgloss::Style.new.foreground('#666666').render('░' * empty)
    end
  end
end
