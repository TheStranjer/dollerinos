# frozen_string_literal: true

require 'json'
require_relative 'trading/config_validator'
require_relative 'trading/constants'
require_relative 'trading/loop_runner'
require_relative 'trading/mcp_clients_builder'
require_relative 'trading/mcp_tool_lister'
require_relative 'trading/service_config'
require_relative 'trading/structs'
require_relative 'trading/system_prompt'
require_relative 'trading/user_prompt_builder'
require_relative 'trading/xai_client'

module Trading
  # Top-level orchestrator: validates configuration, builds MCP/xAI clients,
  # runs the agentic loop, and returns a Trading::Result.
  class GrokTradeService
    Position = Trading::Position
    Trade = Trading::Trade
    Result = Trading::Result
    Error = Trading::ServiceError

    MAX_ITERATIONS = Constants::MAX_ITERATIONS
    FUNCTION_NAME = Constants::FUNCTION_NAME
    HELLTHREAD_LABEL = Constants::HELLTHREAD_LABEL
    UNUSUAL_WHALES_LABEL = Constants::UNUSUAL_WHALES_LABEL
    TOOL_NAME_SEPARATOR = Constants::TOOL_NAME_SEPARATOR

    def initialize(**options)
      @config = ServiceConfig.new(**default_options.merge(options))
    end

    def call
      validation_error = ConfigValidator.new(@config).validate
      return failure(validation_error, 0) if validation_error

      run_with_loop
    rescue ServiceError => e
      failure(e.message, runner_iterations)
    rescue JSON::ParserError
      failure('xAI returned invalid JSON.', runner_iterations)
    rescue StandardError => e
      failure("Trade recommendation generation failed: #{e.message}", runner_iterations)
    end

    private

    DEFAULT_OPTIONS = {
      positions: [],
      max_iterations: MAX_ITERATIONS,
      on_iteration: nil,
      mcp_client_factory: nil,
      xai_client_factory: nil
    }.freeze

    def default_options
      DEFAULT_OPTIONS.merge(
        now: Time.now,
        xai_api_key: ENV.fetch('XAI_API_KEY', nil),
        hellthread_api_key: ENV.fetch('HELLTHREAD_API_KEY', nil),
        unusual_whales_api_key: ENV.fetch('UNUSUAL_WHALES_API_KEY', nil)
      )
    end

    def run_with_loop
      start_time = Time.now
      mcp_tools_by_label = list_mcp_tools
      @runner = build_runner(mcp_tools_by_label)
      trades = @runner.run
      success_result(trades, start_time)
    end

    def list_mcp_tools
      @mcp_clients = McpClientsBuilder.new(@config).build
      McpToolLister.new(@mcp_clients).list
    end

    def build_runner(mcp_tools_by_label)
      LoopRunner.new(
        xai_client: build_xai_client,
        mcp_clients: @mcp_clients,
        mcp_tools_by_label: mcp_tools_by_label,
        initial_input: initial_input,
        max_iterations: @config.max_iterations,
        on_iteration: @config.on_iteration
      )
    end

    def build_xai_client
      factory = @config.xai_client_factory || ->(api_key:) { XaiClient.new(api_key: api_key) }
      factory.call(api_key: @config.xai_api_key)
    end

    def initial_input
      [
        { role: 'system', content: SystemPrompt::BASE },
        { role: 'user', content: UserPromptBuilder.new(
          liquidity_amount: @config.normalized_liquidity,
          positions: @config.normalized_positions
        ).build }
      ]
    end

    def success_result(trades, start_time)
      Result.new(
        trades: trades,
        usage: @runner.usage_totals,
        duration_ms: ((Time.now - start_time) * 1000).round,
        iterations: @runner.iterations_run
      )
    end

    def runner_iterations
      @runner&.iterations_run || 0
    end

    def failure(message, iterations)
      Result.new(trades: [], error_message: message, duration_ms: 0, iterations: iterations)
    end
  end
end
