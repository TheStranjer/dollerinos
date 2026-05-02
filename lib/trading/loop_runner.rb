# frozen_string_literal: true

require_relative 'constants'
require_relative 'iteration_step'
require_relative 'loop_state'
require_relative 'mcp_tool_dispatcher'
require_relative 'output_partition'
require_relative 'structs'
require_relative 'tool_call_executor'
require_relative 'trade_extractor'
require_relative 'usage_accumulator'

module Trading
  # Drives the agentic loop: calls xAI, dispatches MCP tool calls, and
  # returns extracted trades once the model finalizes with `trade_recommendations`.
  class LoopRunner
    REMINDER = 'Please continue: either invoke research tools or finalize by calling ' \
               "#{Constants::FUNCTION_NAME}.".freeze

    def initialize(deps)
      @xai_client = deps.fetch(:xai_client)
      @mcp_clients = deps.fetch(:mcp_clients)
      @mcp_tools_by_label = deps.fetch(:mcp_tools_by_label)
      @max_iterations = deps.fetch(:max_iterations)
      @on_iteration = deps[:on_iteration]
      @state = LoopState.new(initial_input: deps.fetch(:initial_input), now: deps[:now] || Time.now)
      @usage = UsageAccumulator.new
    end

    def run
      @max_iterations.times do
        trades = run_iteration
        return trades if trades
      end

      raise ServiceError, "xAI did not return #{Constants::FUNCTION_NAME} within #{@max_iterations} iterations."
    end

    def iterations_run
      @state.iteration
    end

    def usage_totals
      @usage.to_h
    end

    private

    def run_iteration
      @state.begin_iteration(@max_iterations)
      step = IterationStep.new(iteration: @state.iteration, max_iterations: @max_iterations)
      payload = call_xai(step)
      partition = absorb_payload(payload)
      return finalize_trades(partition) if partition.conclusive?

      run_tool_phase(partition)
      nil
    end

    def call_xai(step)
      payload = @xai_client.post(
        input: @state.input,
        tools: step.tools(@mcp_tools_by_label),
        tool_choice: step.tool_choice
      )
      @usage.add(payload['usage'])
      payload
    end

    def absorb_payload(payload)
      output_items = Array(payload['output'])
      @state.append_outputs(output_items)
      OutputPartition.new(output_items)
    end

    def finalize_trades(partition)
      notify(partition.output_items, [])
      TradeExtractor.new.extract(partition.trade_call)
    end

    def run_tool_phase(partition)
      tool_results = executor.dispatch_all(partition.other_calls, @state)
      notify(partition.output_items, tool_results)
      @state.append_user_reminder(REMINDER) if partition.empty_function_calls?
    end

    def executor
      @executor ||= ToolCallExecutor.new(dispatcher: build_dispatcher)
    end

    def build_dispatcher
      McpToolDispatcher.new(
        mcp_clients: @mcp_clients,
        mcp_tools_by_label: @mcp_tools_by_label
      )
    end

    def notify(output_items, tool_results)
      return unless @on_iteration

      @on_iteration.call(
        iteration: @state.iteration,
        max_iterations: @max_iterations,
        output_items: output_items,
        tool_results: tool_results
      )
    end
  end
end
