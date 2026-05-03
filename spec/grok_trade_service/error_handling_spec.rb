# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'error handling' do
  it 'wraps MCP listing errors in a service error' do
    allow(hellthread_client).to receive(:tools).and_raise(StandardError.new('connection refused'))
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])

    result = build_service(xai_client: xai).call

    expect(result).not_to be_success
    expect(result.error_message).to include('Failed to list tools').or include('connection refused')
  end

  it 'captures JSON::ParserError from xAI as a friendly message' do
    raising_xai = Class.new do
      def post(*) = raise(JSON::ParserError, 'bad')

      def factory
        lambda { |api_key:, har_archiver:|
          _ = api_key
          _ = har_archiver
          self
        }
      end
    end.new

    expect(build_service(xai_client: raising_xai).call.error_message).to include('invalid JSON')
  end
end
