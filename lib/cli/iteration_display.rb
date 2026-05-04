# frozen_string_literal: true

require 'json'

module Cli
  # Renders one iteration's xAI output items and tool results to stdout.
  class IterationDisplay
    SNIPPET_LIMIT = 400

    def initialize(palette)
      @palette = palette
    end

    def render(iteration:, max_iterations:, output_items:, tool_results:)
      puts
      puts @palette[:iteration_header].render("🔄 Iteration #{iteration}/#{max_iterations}")
      puts '-' * 80
      output_items.each { |item| render_item(item) }
      render_tool_results(tool_results) if tool_results.any?
      puts
    end

    private

    def render_tool_results(tool_results)
      puts
      puts @palette[:tool_call].render('⮕ Tool results returned:')
      tool_results.each { |tr| render_tool_result(tr) }
    end

    def render_item(item)
      case item['type']
      when 'function_call' then render_function_call(item)
      when 'web_search_call' then render_web_search_call(item)
      when 'custom_tool_call' then render_custom_tool_call(item)
      when 'message' then render_message_item(item)
      when 'reasoning' then render_reasoning_item(item)
      when 'text' then render_text(item['text'].to_s)
      end
    end

    def render_text(text)
      puts @palette[:prose].render(text) unless text.empty?
    end

    def render_function_call(item)
      puts "  #{@palette[:tool_call].render('🛠  Calling')} #{@palette[:tool_name].render(item['name'].to_s)}"
      pretty_args = format_arguments(item['arguments'].to_s)
      pretty_args.each_line { |line| puts "      #{line.chomp}" }
    end

    def render_web_search_call(item)
      action = item['action'].is_a?(Hash) ? item['action'] : {}
      label = "🔎 web_search (#{action['type'] || 'search'})"
      puts "  #{@palette[:tool_call].render('🛠  Calling')} #{@palette[:tool_name].render(label)}"
      query = action['query'].to_s
      puts "      query: #{query}" unless query.empty?
    end

    def render_custom_tool_call(item)
      label = item['name'].to_s
      label = 'custom_tool_call' if label.empty?
      puts "  #{@palette[:tool_call].render('🛠  Calling')} #{@palette[:tool_name].render(label)}"
      pretty_args = format_arguments(item['input'].to_s)
      pretty_args.each_line { |line| puts "      #{line.chomp}" }
    end

    def render_message_item(item)
      text = MessageContent.text(item['content'])
      render_text(text)
    end

    def render_reasoning_item(item)
      text = MessageContent.summary_text(item)
      return if text.empty?

      puts @palette[:reasoning].render("💭 #{text}")
    end

    def render_tool_result(tool_result)
      result = tool_result[:result].to_s
      snippet = result.length > SNIPPET_LIMIT ? "#{result[0, SNIPPET_LIMIT]}…" : result
      puts "  #{@palette[:tool_name].render(tool_result[:name].to_s)}"
      snippet.each_line { |line| puts "      #{line.chomp}" }
    end

    def format_arguments(raw)
      return '' if raw.nil? || raw.empty?

      JSON.pretty_generate(JSON.parse(raw))
    rescue JSON::ParserError
      raw
    end
  end

  # Plucks display-ready text out of message and reasoning items.
  module MessageContent
    module_function

    def text(content)
      return content.to_s unless content.is_a?(Array)

      content.map { |c| c.is_a?(Hash) ? c['text'] : c }.compact.join("\n")
    end

    def summary_text(item)
      summary = item['summary']
      return text(summary) if summary.is_a?(Array)

      item['text'].to_s
    end
  end
end
