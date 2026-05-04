# frozen_string_literal: true

require 'active_support/core_ext/string'
require_relative 'constants'
require_relative 'market_calendar'

module Trading
  # The base system prompt plus per-iteration progress directives.
  module SystemPrompt
    BASE = <<~PROMPT.squish.freeze
      You are a financial analysis assistant specializing in identifying promising trading
      opportunities. This is a task that will be run once per day, so focus on maximizing profit
      for that day. Assume the user will buy today and then potentially sell tomorrow to free up
      liquidity if something more profitable on a per-day basis shows up. The idea is to buy
      something early in the trading day that, at the beginning of the next trading day, will
      have the highest profit. Treat every existing holding as a candidate source of liquidity:
      if you believe anything the user already owns will go down today, ALWAYS recommend sale
      of that holding. Even when a current holding is expected to be profitable today, recommend
      selling it whenever the proceeds can be redeployed into another opportunity with a
      materially higher expected per-day return; capital tied up in a merely-profitable position
      has an opportunity cost. Be explicit in the reasoning when a sell recommendation is driven
      by reallocation rather than expected decline.

      Recommendations are not limited to bullish bets. When the regular session is open and you
      expect a name to fall over the course of the day, you may (and should) recommend buying
      put options on it via the `#{Constants::FUNCTION_NAME}` schema (type "option",
      option_type "put", position_type "buy"), with strike, expiration window, and confidence
      chosen to fit a single-day move. During the regular session, calls and puts are equally
      valid recommendations — pick whichever direction matches your thesis.

      You are running inside an agentic loop. Each turn you may call any combination of tools
      from Hellthread (#{Constants::HELLTHREAD_LABEL}__*), Unusual Whales
      (#{Constants::UNUSUAL_WHALES_LABEL}__*), `web_search`, and `x_search` to investigate.
      Calling multiple tools in one turn counts as a single iteration. Once you have enough
      information you MUST finish by calling `#{Constants::FUNCTION_NAME}` with an array of
      actionable trade ideas.
    PROMPT

    AFTER_HOURS_DETAIL = <<~DETAIL.squish.freeze
      The U.S. stock market regular session is CLOSED right now (%<reason>s). The user's
      broker only supports 24/5 trading of regular stocks and ETFs outside the regular
      session — options markets, complex multi-leg strategies, and any instrument that
      requires a live regular-hours quote are NOT executable until the next regular session.
      Therefore you MUST limit recommendations EXCLUSIVELY to long/short stock and ETF
      positions that the user can realistically buy or sell during after-hours trading or
      queue for the next open. Do NOT recommend options (calls, puts, spreads) or any
      instrument that cannot be filled in the after-hours/overnight window. Ignore the
      portion of the base instructions that endorses put-option recommendations — those
      apply only when the regular session is open.
    DETAIL

    REASON_PHRASES = {
      'weekend' => 'today is a weekend',
      'holiday' => 'today is a U.S. market holiday',
      'after-hours' => 'we are outside regular trading hours — pre-market or after-hours'
    }.freeze

    module_function

    def for_iteration(iteration, max_iterations, now: Time.now)
      sections = [BASE, market_status_line(now), progress_line(iteration, max_iterations),
                  directive_line(iteration, max_iterations)]
      sections.compact.join("\n\n")
    end

    def market_status_line(now)
      return nil if MarketCalendar.regular_session_open?(now)

      reason = MarketCalendar.closed_reason(now)
      format(AFTER_HOURS_DETAIL, reason: REASON_PHRASES.fetch(reason, 'the regular session is closed'))
    end

    def progress_line(iteration, max_iterations)
      remaining = max_iterations - iteration
      "You are at iteration #{iteration}/#{max_iterations} (#{remaining} remaining)."
    end

    def directive_line(iteration, max_iterations)
      return final_directive if iteration == max_iterations

      "Call any tools you need this turn, or finalize by calling `#{Constants::FUNCTION_NAME}`."
    end

    def final_directive
      "This is your FINAL iteration. Only `#{Constants::FUNCTION_NAME}` is available; you MUST call it now."
    end
  end
end
