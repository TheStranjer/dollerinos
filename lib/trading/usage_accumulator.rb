# frozen_string_literal: true

module Trading
  # Adds up the numeric token-usage figures returned across multiple xAI calls.
  class UsageAccumulator
    def initialize
      @totals = {}
    end

    def add(usage)
      return unless usage.is_a?(Hash)

      usage.each { |key, value| accumulate(key, value) }
    end

    def to_h
      @totals.dup
    end

    private

    def accumulate(key, value)
      return unless value.is_a?(Numeric)

      @totals[key] = (@totals[key] || 0) + value
    end
  end
end
