# frozen_string_literal: true

require 'active_support/core_ext/string'
require_relative 'constants'

module Trading
  # The base system prompt plus per-iteration progress directives.
  module SystemPrompt
    BASE = <<~PROMPT.squish.freeze
      You are a financial analysis assistant specializing in identifying promising trading
      opportunities. This is a task that will be run once per day, so focus on maximizing profit
      for that day. Assume the user will buy today and then potentially sell tomorrow to free up
      liquidity if something more profitable on a per-day basis shows up. The idea is to buy
      something early in the trading day that, at the beginning of the next trading day, will
      have the highest profit. Examine the user's holdings for potential decline; if you believe
      anything the user already owns will go down today, ALWAYS recommend sale of that holding to
      that user.

      You are running inside an agentic loop. Each turn you may call any combination of tools
      from Hellthread (#{Constants::HELLTHREAD_LABEL}__*), Unusual Whales
      (#{Constants::UNUSUAL_WHALES_LABEL}__*), `web_search`, and `x_search` to investigate.
      Calling multiple tools in one turn counts as a single iteration. Once you have enough
      information you MUST finish by calling `#{Constants::FUNCTION_NAME}` with an array of
      actionable trade ideas.
    PROMPT

    module_function

    def for_iteration(iteration, max_iterations)
      [BASE, progress_line(iteration, max_iterations), directive_line(iteration, max_iterations)].join("\n\n")
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
