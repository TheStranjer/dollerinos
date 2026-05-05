# frozen_string_literal: true

require 'json'
require 'mcp'
require_relative 'mcp_tool_fixtures'

# Test fixtures and a service builder for GrokTradeService specs.
module GrokTradeFixtures
  include McpToolFixtures

  def mcp_factory
    lambda do |label:, url:, api_key:, auth: :bearer|
      _ = url
      _ = api_key
      _ = auth
      label_to_client.fetch(label)
    end
  end

  def label_to_client
    {
      Trading::Constants::HELLTHREAD_LABEL => hellthread_client,
      Trading::Constants::UNUSUAL_WHALES_LABEL => unusual_whales_client,
      Trading::Constants::ALPHA_VANTAGE_LABEL => alpha_vantage_client
    }
  end

  def trade_call(trades:, call_id: 'trade_1')
    {
      'type' => 'function_call',
      'id' => "fc_#{call_id}",
      'call_id' => call_id,
      'name' => Trading::Constants::FUNCTION_NAME,
      'arguments' => JSON.generate({ 'trades' => trades })
    }
  end

  def tool_call(name:, arguments: {}, call_id: 'tc_x')
    {
      'type' => 'function_call',
      'id' => "fc_#{call_id}",
      'call_id' => call_id,
      'name' => name,
      'arguments' => JSON.generate(arguments)
    }
  end

  def web_search_output(call_id: 'ws_1')
    { 'type' => 'web_search_call', 'id' => "wsc_#{call_id}", 'call_id' => call_id, 'status' => 'completed' }
  end

  def x_search_output(name: 'x_keyword_search', call_id: 'xs_1')
    {
      'type' => 'custom_tool_call', 'id' => "ctc_#{call_id}", 'call_id' => call_id,
      'name' => name, 'input' => '{}', 'status' => 'completed'
    }
  end

  def valid_trade
    {
      'type' => 'stock', 'symbol' => 'AAPL',
      'min_price' => 150.0, 'max_price' => 160.0,
      'confidence' => 75, 'reasoning' => 'Solid breakout',
      'position_type' => 'buy'
    }
  end

  def text_result(text)
    { 'result' => { 'content' => [{ 'type' => 'text', 'text' => text }] } }
  end

  def build_service(xai_client: nil, **overrides)
    Trading::GrokTradeService.new(**service_defaults(xai_client).merge(overrides))
  end

  def service_defaults(xai_client)
    {
      liquidity_amount: 5000, xai_api_key: 'test_key',
      hellthread_api_key: 'ht_key', unusual_whales_api_key: 'uw_key',
      alpha_vantage_api_key: 'av_key',
      mcp_client_factory: mcp_factory, xai_client_factory: xai_client&.factory
    }
  end
end
