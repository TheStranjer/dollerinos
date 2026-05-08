# frozen_string_literal: true

require_relative 'iteration_listener'
require_relative 'loop_runner'
require_relative 'reconsideration_prompt'
require_relative 'sentiment_analyzer'
require_relative 'usage_accumulator'

module Trading
  # Orchestrates the three-stage trade pipeline:
  #   1. initial agentic loop (gather → open → force_trade_recs)
  #   2. per-pick sentiment analysis (raw, isolated calls — web/x search only)
  #   3. reconsideration loop (full toolset, fresh iteration budget, "are you sure?")
  # Returns an Outcome struct with the final trades, both runners' iteration
  # counts, the sentiment analyses, and the shared usage accumulator.
  class Pipeline
    Outcome = Struct.new(
      :final_trades, :sentiment_analyses, :initial_iterations,
      :reconsideration_iterations, :usage,
      keyword_init: true
    )

    def initialize(deps)
      @xai_client = deps.fetch(:xai_client)
      @mcp_clients = deps.fetch(:mcp_clients)
      @mcp_tools_by_label = deps.fetch(:mcp_tools_by_label)
      @max_iterations = deps.fetch(:max_iterations)
      @initial_input = deps.fetch(:initial_input)
      @listener = deps[:listener] || IterationListener::Null.new
      @now = deps[:now] || Time.now
      @usage = UsageAccumulator.new
    end

    def run
      @initial_runner = build_runner(@initial_input)
      initial_trades = @initial_runner.run
      sentiments = run_sentiment_phase(initial_trades)
      final_trades = run_reconsideration_loop(initial_trades, sentiments)
      build_outcome(final_trades, sentiments)
    end

    def initial_iterations
      @initial_runner&.iterations_run || 0
    end

    private

    def run_sentiment_phase(trades)
      analyzer = SentimentAnalyzer.new(xai_client: @xai_client, listener: @listener, usage_accumulator: @usage)
      analyzer.analyze(trades)
    end

    def run_reconsideration_loop(initial_trades, sentiments)
      preamble = ReconsiderationPrompt.build(sentiments)
      announce_reconsideration(initial_trades, sentiments, preamble)
      input = @initial_runner.state.input.dup << { role: 'user', content: preamble }
      @reconsider_runner = build_runner(input, force_open: true, event_prefix: 'reconsideration_')
      @reconsider_runner.run
    end

    def build_runner(input, force_open: false, event_prefix: '')
      LoopRunner.new(
        xai_client: @xai_client, mcp_clients: @mcp_clients,
        mcp_tools_by_label: @mcp_tools_by_label, initial_input: input,
        max_iterations: @max_iterations, on_iteration: @listener, now: @now,
        usage_accumulator: @usage, force_open: force_open, event_prefix: event_prefix
      )
    end

    def announce_reconsideration(initial_trades, sentiments, preamble)
      return unless @listener.respond_to?(:reconsideration_started)

      @listener.reconsideration_started(
        initial_trades: initial_trades, sentiment_analyses: sentiments, preamble: preamble
      )
    end

    def build_outcome(final_trades, sentiments)
      Outcome.new(
        final_trades: final_trades, sentiment_analyses: sentiments,
        initial_iterations: @initial_runner.iterations_run,
        reconsideration_iterations: @reconsider_runner&.iterations_run || 0,
        usage: @usage.to_h
      )
    end
  end
end
