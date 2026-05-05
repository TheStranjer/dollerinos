# frozen_string_literal: true

require_relative 'constants'
require_relative 'iteration_listener'
require_relative 'iteration_step'
require_relative 'loop_state'
require_relative 'mcp_tool_dispatcher'
require_relative 'output_partition'
require_relative 'quota_tracker'
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
      @listener = deps[:on_iteration] || IterationListener::Null.new
      @state = LoopState.new(initial_input: deps.fetch(:initial_input), now: deps[:now] || Time.now)
      @usage = UsageAccumulator.new
      @quota_tracker = deps[:quota_tracker] || QuotaTracker.new
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
      step = IterationStep.new(
        iteration: @state.iteration + 1, max_iterations: @max_iterations, quota_tracker: @quota_tracker
      )
      tools = step.tools(@mcp_tools_by_label)
      tool_choice = step.tool_choice
      announce_iteration(step, tools, tool_choice)
      partition = absorb_payload(call_xai(tools, tool_choice))
      @quota_tracker.record_outputs(partition.output_items)
      @listener.model_output(output_items: partition.output_items)
      finalize_or_dispatch(partition)
    end

    def announce_iteration(step, tools, tool_choice)
      @state.begin_iteration(@max_iterations, phase: step.phase, unmet_categories: @quota_tracker.unmet_categories)
      @listener.iteration_started(
        iteration: @state.iteration,
        max_iterations: @max_iterations,
        phase: step.phase,
        tools: tools,
        tool_choice: tool_choice
      )
    end

    def call_xai(tools, tool_choice)
      payload = @xai_client.post(input: @state.input, tools: tools, tool_choice: tool_choice)
      @usage.add(payload['usage'])
      payload
    end

    def absorb_payload(payload)
      output_items = Array(payload['output'])
      @state.append_outputs(output_items)
      OutputPartition.new(output_items)
    end

    def finalize_or_dispatch(partition)
      if partition.conclusive?
        trades = TradeExtractor.new.extract(partition.trade_call)
        @listener.iteration_finished(iteration: @state.iteration)
        return trades
      end

      run_tool_phase(partition)
      @listener.iteration_finished(iteration: @state.iteration)
      nil
    end

    def run_tool_phase(partition)
      executor.dispatch_all(partition.other_calls, @state)
      @state.append_user_reminder(REMINDER) if partition.empty_function_calls?
    end

    def executor
      @executor ||= ToolCallExecutor.new(dispatcher: build_dispatcher, listener: @listener)
    end

    def build_dispatcher
      McpToolDispatcher.new(
        mcp_clients: @mcp_clients,
        mcp_tools_by_label: @mcp_tools_by_label
      )
    end
  end
end
