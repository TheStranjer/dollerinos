# frozen_string_literal: true

require 'date'

module Trading
  # Determines whether the U.S. stock market (NYSE) is open on a given date.
  # Closed days are weekends and the standard NYSE-observed holidays.
  module MarketCalendar
    module_function

    def open?(date_or_time)
      date = to_date(date_or_time)
      !weekend?(date) && !holiday?(date)
    end

    def closed?(date_or_time)
      !open?(date_or_time)
    end

    def closed_reason(date_or_time)
      date = to_date(date_or_time)
      return 'weekend' if weekend?(date)
      return 'holiday' if holiday?(date)

      nil
    end

    def weekend?(date)
      date.saturday? || date.sunday?
    end

    def holiday?(date)
      holidays_for(date.year).include?(date)
    end

    def holidays_for(year)
      fixed_date_holidays(year) + floating_holidays(year) + [good_friday(year)]
    end

    def fixed_date_holidays(year)
      [[1, 1], [6, 19], [7, 4], [12, 25]].map { |month, day| observed(Date.new(year, month, day)) }
    end

    def floating_holidays(year)
      [
        nth_weekday_of_month(year, 1, 1, 3),
        nth_weekday_of_month(year, 2, 1, 3),
        last_weekday_of_month(year, 5, 1),
        nth_weekday_of_month(year, 9, 1, 1),
        nth_weekday_of_month(year, 11, 4, 4)
      ]
    end

    def observed(date)
      return date - 1 if date.saturday?
      return date + 1 if date.sunday?

      date
    end

    def nth_weekday_of_month(year, month, wday, occurrence)
      first = Date.new(year, month, 1)
      offset = (wday - first.wday) % 7
      first + offset + ((occurrence - 1) * 7)
    end

    def last_weekday_of_month(year, month, wday)
      last = Date.new(year, month, -1)
      offset = (last.wday - wday) % 7
      last - offset
    end

    def good_friday(year)
      easter_sunday(year) - 2
    end

    # Anonymous Gregorian computus for Easter Sunday.
    def easter_sunday(year)
      h, l = paschal_factors(year)
      m = (year % 19) + (11 * h) + (22 * l)
      raw = h + l - (7 * (m / 451)) + 114
      Date.new(year, raw / 31, (raw % 31) + 1)
    end

    def paschal_factors(year)
      metonic = year % 19
      century, year_in_century = year.divmod(100)
      epact = paschal_h(metonic, century)
      [epact, paschal_l(century, year_in_century, epact)]
    end

    def paschal_h(metonic_remainder, century)
      d = century / 4
      f = (century + 8) / 25
      g = (century - f + 1) / 3
      ((19 * metonic_remainder) + century - d - g + 15) % 30
    end

    def paschal_l(century, year_in_century, epact)
      e = century % 4
      i, k = year_in_century.divmod(4)
      (32 + (2 * e) + (2 * i) - epact - k) % 7
    end

    def to_date(input)
      return input if input.is_a?(Date) && !input.is_a?(DateTime)

      input.to_date
    end
  end
end
