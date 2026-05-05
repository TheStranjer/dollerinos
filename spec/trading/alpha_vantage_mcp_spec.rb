# frozen_string_literal: true

require_relative '../../lib/trading/constants'
require_relative '../../lib/trading/mcp_client_factory'
require_relative '../../lib/trading/mcp_clients_builder'
require_relative '../../lib/trading/quota_tracker'
require_relative '../../lib/trading/service_config'
require_relative '../../lib/trading/config_validator'

module AlphaVantageHttpCapture
  def capture_http_args
    captured = {}
    fake_transport = Object.new
    allow(MCP::Client::HTTP).to receive(:new) do |**kwargs|
      captured.replace(kwargs)
      fake_transport
    end
    allow(MCP::Client).to receive(:new).with(transport: fake_transport).and_return(:client)
    yield captured if block_given?
    captured
  end
end

RSpec.configure { |c| c.include AlphaVantageHttpCapture }

describe Trading::Constants, 'Alpha Vantage' do
  it 'defines an alpha-vantage label' do
    expect(described_class::ALPHA_VANTAGE_LABEL).to eq('alpha-vantage')
  end

  it 'embeds the API key as a query parameter via a format placeholder' do
    expect(described_class::ALPHA_VANTAGE_URL).to eq('https://mcp.alphavantage.co/mcp?apikey=%<api_key>s')
  end
end

describe Trading::QuotaTracker, 'Alpha Vantage quota' do
  let(:tracker) { described_class.new }

  it 'requires at least 5 invocations to satisfy the alpha-vantage quota' do
    4.times { tracker.record_outputs([{ 'type' => 'function_call', 'name' => 'alpha-vantage__time_series_daily' }]) }
    expect(tracker.met?('alpha-vantage')).to be(false)

    tracker.record_outputs([{ 'type' => 'function_call', 'name' => 'alpha-vantage__time_series_daily' }])
    expect(tracker.met?('alpha-vantage')).to be(true)
  end

  it 'lists alpha-vantage among the categories' do
    expect(described_class::CATEGORIES).to include('alpha-vantage')
    expect(described_class::QUOTAS.fetch('alpha-vantage')).to eq(5)
  end
end

describe Trading::ConfigValidator, 'Alpha Vantage key' do
  def config_with(**overrides)
    Trading::ServiceConfig.new(
      liquidity_amount: 1000, xai_api_key: 'x', hellthread_api_key: 'h',
      unusual_whales_api_key: 'u', alpha_vantage_api_key: 'a',
      max_iterations: 1, **overrides
    )
  end

  it 'fails when the alpha_vantage_api_key is missing' do
    expect(described_class.new(config_with(alpha_vantage_api_key: nil)).validate).to include('ALPHA_VANTAGE_API_KEY')
  end

  it 'passes when all keys are configured' do
    expect(described_class.new(config_with).validate).to be_nil
  end
end

describe Trading::McpClientFactory, ':query auth style' do
  it 'inlines the API key into the URL when auth: :query' do
    captured = capture_http_args do
      described_class.build(
        label: 'alpha-vantage',
        url: 'https://mcp.alphavantage.co/mcp?apikey=%<api_key>s',
        api_key: 'SECRET_KEY',
        auth: :query
      )
    end
    expect(captured[:url]).to eq('https://mcp.alphavantage.co/mcp?apikey=SECRET_KEY')
    expect(captured).not_to have_key(:headers)
  end
end

describe Trading::McpClientFactory, ':bearer auth style' do
  it 'uses an Authorization header when auth: :bearer' do
    captured = capture_http_args do
      described_class.build(label: 'hellthread', url: 'https://example.com', api_key: 'TOK', auth: :bearer)
    end
    expect(captured[:headers]).to eq('Authorization' => 'Bearer TOK')
  end
end

describe Trading::McpClientsBuilder, 'Alpha Vantage wiring' do
  it 'requests an alpha-vantage client with :query auth and the alpha_vantage_api_key' do
    config = Trading::ServiceConfig.new(
      liquidity_amount: 1000, xai_api_key: 'x', hellthread_api_key: 'h',
      unusual_whales_api_key: 'u', alpha_vantage_api_key: 'AV_KEY', max_iterations: 1
    )
    seen = []
    config.mcp_client_factory = lambda do |label:, url:, api_key:, auth: :bearer|
      seen << { label: label, url: url, api_key: api_key, auth: auth }
      :stub_client
    end

    described_class.new(config).build

    av = seen.find { |s| s[:label] == 'alpha-vantage' }
    expect(av).to include(
      url: 'https://mcp.alphavantage.co/mcp?apikey=%<api_key>s', api_key: 'AV_KEY', auth: :query
    )
  end
end
