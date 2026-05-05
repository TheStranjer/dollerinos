# frozen_string_literal: true

require 'mcp'

# Per-server MCP tool/client fixtures consumed by GrokTradeFixtures.
module McpToolFixtures
  def hellthread_tool
    @hellthread_tool ||= MCP::Client::Tool.new(
      name: 'search_4chan', description: 'Search 4chan /biz/',
      input_schema: { 'type' => 'object', 'properties' => { 'query' => { 'type' => 'string' } } }
    )
  end

  def unusual_whales_tool
    @unusual_whales_tool ||= MCP::Client::Tool.new(
      name: 'flow_alerts', description: 'Get unusual options flow',
      input_schema: { 'type' => 'object', 'properties' => { 'ticker' => { 'type' => 'string' } } }
    )
  end

  def alpha_vantage_tool
    @alpha_vantage_tool ||= MCP::Client::Tool.new(
      name: 'time_series_daily', description: 'Daily time series for a symbol',
      input_schema: { 'type' => 'object', 'properties' => { 'symbol' => { 'type' => 'string' } } }
    )
  end

  def hellthread_client
    @hellthread_client ||= instance_double(MCP::Client, tools: [hellthread_tool])
  end

  def unusual_whales_client
    @unusual_whales_client ||= instance_double(MCP::Client, tools: [unusual_whales_tool])
  end

  def alpha_vantage_client
    @alpha_vantage_client ||= instance_double(MCP::Client, tools: [alpha_vantage_tool])
  end

  def hellthread_tool_full_name
    "#{Trading::Constants::HELLTHREAD_LABEL}#{Trading::Constants::TOOL_NAME_SEPARATOR}search_4chan"
  end

  def unusual_whales_tool_full_name
    "#{Trading::Constants::UNUSUAL_WHALES_LABEL}#{Trading::Constants::TOOL_NAME_SEPARATOR}flow_alerts"
  end

  def alpha_vantage_tool_full_name
    "#{Trading::Constants::ALPHA_VANTAGE_LABEL}#{Trading::Constants::TOOL_NAME_SEPARATOR}time_series_daily"
  end
end
