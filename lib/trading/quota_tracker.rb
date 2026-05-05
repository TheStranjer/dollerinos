# frozen_string_literal: true

require_relative 'constants'
require_relative 'tool_name_codec'

module Trading
  # Tracks how many times each research-tool category has been invoked across
  # iterations. Used by IterationStep/XaiToolSpecs to gate tool exposure into
  # three phases: gather (hide met categories and trade_recs), open (expose
  # everything), and force (trade_recs only).
  class QuotaTracker
    WEB_SEARCH = 'web_search'
    X_SEARCH = 'x_search'
    HELLTHREAD = Constants::HELLTHREAD_LABEL
    UNUSUAL_WHALES = Constants::UNUSUAL_WHALES_LABEL
    ALPHA_VANTAGE = Constants::ALPHA_VANTAGE_LABEL

    QUOTAS = {
      WEB_SEARCH => 5,
      X_SEARCH => 5,
      HELLTHREAD => 5,
      UNUSUAL_WHALES => 10,
      ALPHA_VANTAGE => 5
    }.freeze

    CATEGORIES = QUOTAS.keys.freeze

    def initialize(quotas: QUOTAS)
      @quotas = quotas
      @counts = quotas.each_key.to_h { |k| [k, 0] }
    end

    def record_outputs(output_items)
      Array(output_items).each { |item| record_item(item) }
    end

    def met?(category)
      @counts.fetch(category, 0) >= @quotas.fetch(category, 0)
    end

    def all_met?
      @quotas.each_key.all? { |c| met?(c) }
    end

    def unmet_categories
      @quotas.each_key.reject { |c| met?(c) }
    end

    def counts
      @counts.dup
    end

    private

    def record_item(item)
      category = categorize(item)
      return unless category && @counts.key?(category)

      @counts[category] += 1
    end

    def categorize(item)
      return nil unless item.is_a?(Hash)

      type = item['type'].to_s
      return WEB_SEARCH if type == 'web_search_call'
      return X_SEARCH if type == 'custom_tool_call'
      return nil unless type == 'function_call'

      label, _tool = ToolNameCodec.decode(item['name'])
      label
    end
  end
end
