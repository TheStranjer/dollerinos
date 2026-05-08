# frozen_string_literal: true

require 'json'
require_relative 'har_archiver'
require_relative 'trading/config_validator'
require_relative 'trading/constants'
require_relative 'trading/iteration_listener'
require_relative 'trading/mcp_clients_builder'
require_relative 'trading/mcp_tool_lister'
require_relative 'trading/pipeline'
require_relative 'trading/service_config'
require_relative 'trading/structs'
require_relative 'trading/system_prompt'
require_relative 'trading/user_prompt_builder'
require_relative 'trading/xai_client'

module Trading
  # Top-level orchestrator: validates configuration, builds MCP/xAI clients,
  # runs the three-stage trade pipeline (initial loop → sentiment analysis →
  # reconsideration loop), and returns a Trading::Result.
  class GrokTradeService
    Position = Trading::Position
    Trade = Trading::Trade
    Result = Trading::Result
    Error = Trading::ServiceError

    MAX_ITERATIONS = Constants::MAX_ITERATIONS
    FUNCTION_NAME = Constants::FUNCTION_NAME
    HELLTHREAD_LABEL = Constants::HELLTHREAD_LABEL
    UNUSUAL_WHALES_LABEL = Constants::UNUSUAL_WHALES_LABEL
    ALPHA_VANTAGE_LABEL = Constants::ALPHA_VANTAGE_LABEL
    TOOL_NAME_SEPARATOR = Constants::TOOL_NAME_SEPARATOR

    def initialize(**options)
      @config = ServiceConfig.new(**default_options.merge(options))
    end

    def call
      validation_error = ConfigValidator.new(@config).validate
      return failure(validation_error, 0) if validation_error

      run_with_pipeline
    rescue ServiceError => e
      failure(e.message, pipeline_iterations)
    rescue JSON::ParserError
      failure('xAI returned invalid JSON.', pipeline_iterations)
    rescue StandardError => e
      failure("Trade recommendation generation failed: #{e.message}", pipeline_iterations)
    end

    private

    def default_options
      {
        positions: [], max_iterations: MAX_ITERATIONS, on_iteration: nil,
        mcp_client_factory: nil, xai_client_factory: nil, user_prompt: nil,
        now: Time.now,
        xai_api_key: ENV.fetch('XAI_API_KEY', nil),
        hellthread_api_key: ENV.fetch('HELLTHREAD_API_KEY', nil),
        unusual_whales_api_key: ENV.fetch('UNUSUAL_WHALES_API_KEY', nil),
        alpha_vantage_api_key: ENV.fetch('ALPHA_VANTAGE_API_KEY', nil)
      }
    end

    def run_with_pipeline
      start_time = Time.now
      mcp_tools_by_label = list_mcp_tools
      @pipeline = build_pipeline(mcp_tools_by_label)
      outcome = @pipeline.run
      success_result(outcome, start_time)
    end

    def list_mcp_tools
      @mcp_clients = McpClientsBuilder.new(@config).build
      McpToolLister.new(@mcp_clients).list
    end

    def build_pipeline(mcp_tools_by_label)
      Pipeline.new(
        xai_client: build_xai_client, mcp_clients: @mcp_clients,
        mcp_tools_by_label: mcp_tools_by_label, max_iterations: @config.max_iterations,
        initial_input: initial_input, listener: listener, now: @config.now
      )
    end

    def build_xai_client
      keys = [@config.xai_api_key, @config.hellthread_api_key, @config.unusual_whales_api_key,
              @config.alpha_vantage_api_key]
      archiver = HarArchiver.new(sensitive_values: keys)
      factory = @config.xai_client_factory ||
                ->(api_key:, har_archiver:) { XaiClient.new(api_key: api_key, har_archiver: har_archiver) }
      factory.call(api_key: @config.xai_api_key, har_archiver: archiver)
    end

    def initial_input
      messages = [{ role: 'system', content: SystemPrompt::BASE }]
      custom = custom_user_prompt
      messages << { role: 'user', content: custom } if custom
      messages << { role: 'user', content: UserPromptBuilder.new(
        liquidity_amount: @config.normalized_liquidity,
        positions: @config.normalized_positions
      ).build }
      messages
    end

    def custom_user_prompt
      raw = @config.user_prompt
      return nil if raw.nil?

      stripped = raw.to_s.strip
      stripped.empty? ? nil : stripped
    end

    def listener
      @config.on_iteration || IterationListener::Null.new
    end

    def success_result(outcome, start_time)
      Result.new(
        trades: outcome.final_trades, usage: outcome.usage,
        duration_ms: ((Time.now - start_time) * 1000).round,
        iterations: outcome.initial_iterations,
        reconsideration_iterations: outcome.reconsideration_iterations,
        sentiment_analyses: outcome.sentiment_analyses
      )
    end

    def pipeline_iterations
      @pipeline&.initial_iterations || 0
    end

    def failure(message, iterations)
      Result.new(
        trades: [], error_message: message, duration_ms: 0,
        iterations: iterations, reconsideration_iterations: 0, sentiment_analyses: []
      )
    end
  end
end
