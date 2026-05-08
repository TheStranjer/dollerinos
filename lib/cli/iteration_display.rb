# frozen_string_literal: true

require 'json'
require_relative 'extra_phase_display'
require_relative 'output_item_renderer'

module Cli
  # Renders one iteration of the agentic loop progressively to stdout: announces
  # the iteration and exposed tools before the model responds, prints the model's
  # output items as they arrive, and prints each tool call and its result as the
  # call is dispatched (so users can see Alpha Vantage throttling in real time).
  class IterationDisplay
    SNIPPET_LIMIT = 400

    PHASE_LABELS = {
      gather: 'gather',
      open: 'open',
      force_trade_recs: 'force_trade_recs'
    }.freeze

    def initialize(palette, io: $stdout)
      @palette = palette
      @io = io
      @item_renderer = OutputItemRenderer.new(palette, io)
    end

    def iteration_started(iteration:, max_iterations:, phase:, tools:, tool_choice:)
      @io.puts
      @io.puts @palette[:iteration_header].render("🔄 Starting Iteration #{iteration}/#{max_iterations}")
      @io.puts '-' * 80
      @io.puts "  #{phase_label}: #{render_phase(phase)}  #{tool_choice_label}: #{render_tool_choice(tool_choice)}"
      render_tool_list(tools)
      flush
    end

    def model_output(output_items:)
      output_items.each { |item| @item_renderer.render(item) }
      flush
    end

    def tool_call_started(function_call:)
      name = function_call['name'].to_s
      @io.puts "  #{@palette[:tool_call].render('🛠  Calling')} #{@palette[:tool_name].render(name)}"
      pretty = format_arguments(function_call['arguments'].to_s)
      pretty.each_line { |line| @io.puts "      #{line.chomp}" }
      flush
    end

    def tool_call_completed(function_call:, result:)
      _ = function_call
      raw = result[:result].to_s
      snippet = raw.length > SNIPPET_LIMIT ? "#{raw[0, SNIPPET_LIMIT]}…" : raw
      @io.puts "      #{@palette[:tool_call].render('↪ result:')}"
      snippet.each_line { |line| @io.puts "        #{line.chomp}" }
      flush
    end

    def iteration_finished(**)
      @io.puts
    end

    include ExtraPhaseDisplay

    private

    def flush
      @io.flush if @io.respond_to?(:flush)
    end

    def phase_label
      @palette[:info_label].render('phase')
    end

    def tool_choice_label
      @palette[:info_label].render('tool_choice')
    end

    def render_phase(phase)
      label = PHASE_LABELS.fetch(phase, phase.to_s)
      @palette[:tool_name].render(label)
    end

    def render_tool_choice(tool_choice)
      text = tool_choice.is_a?(Hash) ? "function:#{tool_choice[:name] || tool_choice['name']}" : tool_choice.to_s
      @palette[:tool_call].render(text)
    end

    def render_tool_list(tools)
      @io.puts "  #{@palette[:info_label].render('Tools exposed to LLM:')}"
      if tools.empty?
        @io.puts "    #{@palette[:info_label].render('(none)')}"
        return
      end
      tools.each { |tool| @io.puts "    • #{@palette[:tool_name].render(tool_label(tool))}" }
    end

    def tool_label(tool)
      type = tool[:type] || tool['type']
      name = tool[:name] || tool['name']
      return name.to_s if type.to_s == 'function' && name
      return type.to_s if type

      'unknown'
    end

    def format_arguments(raw)
      return '' if raw.nil? || raw.empty?

      JSON.pretty_generate(JSON.parse(raw))
    rescue JSON::ParserError
      raw
    end
  end
end
