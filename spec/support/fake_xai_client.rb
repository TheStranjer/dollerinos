# frozen_string_literal: true

# A scripted xAI client double: each call returns the next payload from the
# queue and records the input/tools/tool_choice for later inspection.
class FakeXaiClient
  attr_reader :calls

  def initialize(payloads)
    @payloads = payloads.dup
    @calls = []
  end

  def post(input:, tools:, tool_choice:)
    @calls << { input: deep_dup(input), tools: tools, tool_choice: tool_choice }
    raise 'FakeXaiClient ran out of scripted payloads' if @payloads.empty?

    @payloads.shift
  end

  def factory
    lambda { |api_key:, har_archiver:|
      _ = api_key
      _ = har_archiver
      self
    }
  end

  private

  def deep_dup(items)
    items.map { |item| item.is_a?(Hash) ? item.dup : item }
  end
end
