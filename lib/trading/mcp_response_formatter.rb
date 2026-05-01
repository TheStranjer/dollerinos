# frozen_string_literal: true

require 'json'

module Trading
  # Converts raw MCP JSON-RPC responses into the text payloads we feed back to xAI.
  module McpResponseFormatter
    module_function

    def format(response)
      return JSON.generate(response) unless response.is_a?(Hash)

      result = response['result']
      return JSON.generate(response) unless result.is_a?(Hash)

      format_result(result)
    end

    def format_result(result)
      from_content(result['content']) || from_structured(result['structuredContent']) || JSON.generate(result)
    end

    def from_content(content)
      return nil unless content.is_a?(Array) && content.any?

      content.map { |item| extract_text(item) }.join("\n")
    end

    def from_structured(structured)
      return nil unless structured

      JSON.generate(structured)
    end

    def extract_text(item)
      return item.to_s unless item.is_a?(Hash)

      item['text'] || JSON.generate(item)
    end
  end
end
