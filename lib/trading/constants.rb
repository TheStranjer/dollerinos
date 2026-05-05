# frozen_string_literal: true

module Trading
  module Constants
    MAX_ITERATIONS = 10
    FUNCTION_NAME = 'trade_recommendations'
    MODEL_NAME = 'grok-4.3'
    XAI_RESPONSES_URL = 'https://api.x.ai/v1/responses'

    HELLTHREAD_LABEL = 'hellthread'
    HELLTHREAD_URL = 'https://hellthread.cyou/mcp/messages'
    UNUSUAL_WHALES_LABEL = 'unusual-whales'
    UNUSUAL_WHALES_URL = 'https://api.unusualwhales.com/api/mcp'
    ALPHA_VANTAGE_LABEL = 'alpha-vantage'
    ALPHA_VANTAGE_URL = 'https://mcp.alphavantage.co/mcp?apikey=%<api_key>s'

    TOOL_NAME_SEPARATOR = '__'
  end
end
