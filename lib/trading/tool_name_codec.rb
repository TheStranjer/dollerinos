# frozen_string_literal: true

require_relative 'constants'

module Trading
  # Encodes/decodes namespaced MCP tool names (e.g. "hellthread__search_4chan").
  module ToolNameCodec
    SEPARATOR = Constants::TOOL_NAME_SEPARATOR

    module_function

    def encode(label, tool_name)
      "#{label}#{SEPARATOR}#{tool_name}"
    end

    def decode(name)
      str = name.to_s
      idx = str.index(SEPARATOR)
      return [nil, nil] unless idx

      [str[0...idx], str[(idx + SEPARATOR.length)..]]
    end
  end
end
