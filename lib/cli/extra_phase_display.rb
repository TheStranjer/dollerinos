# frozen_string_literal: true

module Cli
  # Mixin that adds the sentiment and reconsideration listener events to
  # IterationDisplay. Reconsideration events delegate back to the host's
  # iteration_*/tool_call_* methods so the same rendering code is reused.
  module ExtraPhaseDisplay
    SENTIMENT_TEXT_LIMIT = 1200

    def sentiment_started(trade:)
      @io.puts
      @io.puts "#{@palette[:iteration_header].render('🧠 Sentiment analysis:')} #{sentiment_label(trade)}"
      @io.puts '-' * 80
      flush
    end

    def sentiment_completed(trade:, sentiment:)
      _ = trade
      raw = sentiment.to_s
      snippet = raw.length > SENTIMENT_TEXT_LIMIT ? "#{raw[0, SENTIMENT_TEXT_LIMIT]}…" : raw
      snippet.each_line { |line| @io.puts "  #{line.chomp}" }
      @io.puts
      flush
    end

    def reconsideration_started(initial_trades:, sentiment_analyses:, preamble:)
      _ = initial_trades
      _ = sentiment_analyses
      _ = preamble
      @io.puts
      @io.puts @palette[:iteration_header].render('🔁 Reconsideration phase')
      @io.puts '-' * 80
      @io.puts '  Iteration budget reset; all research tools are available again.'
      @io.puts
      flush
    end

    def reconsideration_iteration_started(**payload)
      iteration_started(**payload)
    end

    def reconsideration_model_output(**payload)
      model_output(**payload)
    end

    def reconsideration_tool_call_started(**payload)
      tool_call_started(**payload)
    end

    def reconsideration_tool_call_completed(**payload)
      tool_call_completed(**payload)
    end

    def reconsideration_iteration_finished(**payload)
      iteration_finished(**payload)
    end

    private

    def sentiment_label(trade)
      symbol_style = trade.option? ? @palette[:option_symbol] : @palette[:stock_symbol]
      type_style = trade.option? ? @palette[:options_title] : @palette[:stocks_title]
      type_text = trade.option? ? "option/#{trade.option_type&.upcase || '?'}" : 'stock'
      "#{type_style.render(type_text)} #{symbol_style.render(trade.symbol.to_s)}"
    end
  end
end
