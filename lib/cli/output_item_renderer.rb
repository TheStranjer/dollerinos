# frozen_string_literal: true

require 'json'

module Cli
  # Renders xAI response output items (function_call requests, web_search calls,
  # custom_tool calls, messages, reasoning, plain text) to a configured IO using
  # the supplied palette. Used by IterationDisplay during the model_output phase.
  class OutputItemRenderer
    def initialize(palette, io)
      @palette = palette
      @io = io
    end

    def render(item)
      case item['type']
      when 'function_call' then render_function_call(item)
      when 'web_search_call' then render_web_search_call(item)
      when 'custom_tool_call' then render_custom_tool_call(item)
      when 'message' then render_text(MessageContent.text(item['content']))
      when 'reasoning' then render_reasoning_item(item)
      when 'text' then render_text(item['text'].to_s)
      end
    end

    private

    def render_text(text)
      @io.puts @palette[:prose].render(text) unless text.empty?
    end

    def render_function_call(item)
      @io.puts "  #{@palette[:tool_call].render('📨 Model requested')} " \
               "#{@palette[:tool_name].render(item['name'].to_s)}"
      indent_args(item['arguments'].to_s)
    end

    def render_web_search_call(item)
      action = item['action'].is_a?(Hash) ? item['action'] : {}
      label = "🔎 web_search (#{action['type'] || 'search'})"
      @io.puts "  #{@palette[:tool_call].render('🛠  Calling')} #{@palette[:tool_name].render(label)}"
      query = action['query'].to_s
      @io.puts "      query: #{query}" unless query.empty?
    end

    def render_custom_tool_call(item)
      label = item['name'].to_s
      label = 'custom_tool_call' if label.empty?
      @io.puts "  #{@palette[:tool_call].render('🛠  Calling')} #{@palette[:tool_name].render(label)}"
      indent_args(item['input'].to_s)
    end

    def render_reasoning_item(item)
      text = MessageContent.summary_text(item)
      return if text.empty?

      @io.puts @palette[:reasoning].render("💭 #{text}")
    end

    def indent_args(raw)
      pretty = format_arguments(raw)
      pretty.each_line { |line| @io.puts "      #{line.chomp}" }
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
