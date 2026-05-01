# frozen_string_literal: true

require_relative 'constants'

module Trading
  # Partitions an xAI response's output array into trade-recommendation calls
  # and other tool calls, exposing predicates the loop runner uses to decide
  # whether the iteration is conclusive.
  class OutputPartition
    attr_reader :output_items, :function_calls, :trade_call, :other_calls

    def initialize(output_items)
      @output_items = output_items
      @function_calls = output_items.select { |item| item['type'] == 'function_call' }
      @trade_call = @function_calls.find { |c| c['name'] == Constants::FUNCTION_NAME }
      @other_calls = @function_calls.reject { |c| c['name'] == Constants::FUNCTION_NAME }
    end

    def conclusive?
      trade_call && other_calls.empty?
    end

    def empty_function_calls?
      function_calls.empty?
    end
  end
end
