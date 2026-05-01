# frozen_string_literal: true

require 'lipgloss'

module Cli
  # Centralised Lipgloss styles used by the recommender CLI.
  module Styles
    DEFINITIONS = {
      header: { bold: true, fg: '#00D7FF' },
      stocks_title: { bold: true, fg: '#00FF00' },
      options_title: { bold: true, fg: '#FFFF00' },
      stock_symbol: { fg: '#00D7FF' },
      option_symbol: { fg: '#FF00FF' },
      error: { bold: true, fg: '#FF0000' },
      info_label: { fg: '#AAAAAA' },
      perf_title: { bold: true, fg: '#00D7FF' },
      duration: { fg: '#FFD700' },
      input_tokens: { fg: '#00D7FF' },
      output_tokens: { fg: '#00FF00' },
      reasoning_tokens: { fg: '#FFFF00' },
      total_tokens: { bold: true, fg: '#FF00FF' },
      token_value: { bold: true, fg: '#FFFFFF' },
      buy_action: { bold: true, fg: '#00FF00' },
      sell_action: { bold: true, fg: '#FF0000' },
      iteration_header: { bold: true, fg: '#FF8C00' },
      tool_call: { fg: '#87CEFA' },
      tool_name: { bold: true, fg: '#FFB347' },
      prose: { fg: '#DDDDDD' },
      reasoning: { italic: true, fg: '#888888' }
    }.freeze

    module_function

    def palette
      DEFINITIONS.transform_values { |spec| build_style(spec) }
    end

    def build_style(spec)
      style = Lipgloss::Style.new
      style = style.bold(true) if spec[:bold]
      style = style.italic(true) if spec[:italic]
      style.foreground(spec[:fg])
    end
  end
end
