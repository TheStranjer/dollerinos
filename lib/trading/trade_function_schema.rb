# frozen_string_literal: true

module Trading
  # JSON Schema for the trade_recommendations function exposed to xAI.
  module TradeFunctionSchema
    REQUIRED_FIELDS = %w[type symbol min_price max_price confidence reasoning position_type].freeze

    ITEM_PROPERTIES = {
      type: { type: 'string', enum: %w[stock option] },
      symbol: { type: 'string' },
      min_price: { type: 'number' },
      max_price: { type: 'number' },
      confidence: { type: 'integer', minimum: 0, maximum: 100 },
      reasoning: { type: 'string' },
      strike_price: { type: 'number' },
      expiration_date_min: { type: 'string' },
      expiration_date_max: { type: 'string' },
      option_type: { type: 'string', enum: %w[call put] },
      position_type: { type: 'string', enum: %w[buy sell] }
    }.freeze

    module_function

    def schema
      {
        type: 'object',
        properties: { trades: trades_property },
        required: ['trades'],
        additionalProperties: false
      }
    end

    def trades_property
      { type: 'array', items: item_schema }
    end

    def item_schema
      {
        type: 'object',
        properties: ITEM_PROPERTIES,
        required: REQUIRED_FIELDS,
        additionalProperties: false
      }
    end
  end
end
