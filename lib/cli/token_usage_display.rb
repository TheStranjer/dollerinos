# frozen_string_literal: true

require_relative 'format_helpers'

module Cli
  # Renders the token-usage and timing block at the end of a run.
  class TokenUsageDisplay
    LABELS = {
      input_tokens: 'Input Tokens:',
      output_tokens: 'Output Tokens:',
      reasoning_tokens: 'Reasoning Tokens:',
      total_tokens: 'Total Tokens:'
    }.freeze

    def initialize(palette)
      @palette = palette
    end

    def render(usage, duration_ms = 0)
      counts = TokenUsageCounts.from(usage)
      puts
      puts @palette[:perf_title].render('📊 Query Performance & Token Usage')
      puts '=' * 80
      render_duration(duration_ms) if duration_ms.positive?
      render_counts(counts)
      puts
    end

    private

    def render_duration(duration_ms)
      formatted = FormatHelpers.format_duration(duration_ms)
      puts "  #{@palette[:duration].render('Resolution Time:')}  #{@palette[:token_value].render(formatted)}"
    end

    def render_counts(counts)
      render_count(:input_tokens, counts.input)
      render_count(:output_tokens, counts.output)
      render_count(:reasoning_tokens, counts.reasoning) if counts.reasoning.positive?
      render_count(:total_tokens, counts.total)
    end

    def render_count(style_key, value)
      label = @palette[style_key].render(LABELS.fetch(style_key))
      puts "  #{label} #{@palette[:token_value].render(FormatHelpers.format_number(value))}"
    end
  end

  # Aggregates token counts pulled from a usage hash.
  TokenUsageCounts = Struct.new(:input, :output, :reasoning, :total) do
    def self.from(usage)
      input = usage['input_tokens'] || 0
      output = usage['output_tokens'] || 0
      reasoning = usage['reasoning_tokens'] || 0
      total = usage['total_tokens'] || (input + output + reasoning)
      new(input, output, reasoning, total)
    end
  end
end
