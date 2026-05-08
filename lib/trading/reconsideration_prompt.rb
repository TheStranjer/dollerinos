# frozen_string_literal: true

require_relative 'constants'

module Trading
  # Builds the user-message preamble that opens the reconsideration loop. It
  # summarises the picks the initial loop produced, attaches each pick's
  # sentiment-analysis text, lists the tools available again, and asks the
  # model "are you sure?" before resetting the iteration budget.
  module ReconsiderationPrompt
    module_function

    def build(sentiment_analyses)
      sections = [header, body(sentiment_analyses), tools_reminder, ask]
      sections.join("\n\n")
    end

    def header
      'RECONSIDERATION CHECKPOINT — your initial picks have been audited with a ' \
        'fresh round of sentiment analysis (web + X search) and the iteration ' \
        'budget has been reset.'
    end

    def body(sentiment_analyses)
      return 'No picks were produced in the initial loop.' if sentiment_analyses.empty?

      sections = sentiment_analyses.map { |analysis| analysis_block(analysis) }
      (['Per-pick sentiment summaries:'] + sections).join("\n\n")
    end

    def analysis_block(analysis)
      trade = analysis.trade
      "- #{label_for(trade)}\n  Sentiment: #{format_text(analysis.text)}"
    end

    def label_for(trade)
      details = [trade.type, trade.symbol]
      details << "#{trade.option_type} #{trade.position_type}" if trade.option?
      details << "$#{trade.min_price}-$#{trade.max_price}" if trade.min_price.to_f.positive?
      details.compact.join(' ')
    end

    def format_text(text)
      stripped = text.to_s.strip
      stripped.empty? ? '(no sentiment text returned)' : stripped
    end

    def tools_reminder
      'Available tools: hellthread__*, unusual-whales__*, alpha-vantage__*, ' \
        'web_search, x_search, and the trade_recommendations finalizer.'
    end

    def ask
      'Are you sure about your picks? You may keep the same set, modify them, or ' \
        'drop/add picks based on the sentiment data. You have a fresh budget of ' \
        'iterations and may use any combination of research tools before you ' \
        "finalize. When you are ready, call `#{Constants::FUNCTION_NAME}` with your " \
        'final, locked-in picks.'
    end
  end
end
