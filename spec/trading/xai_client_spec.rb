# frozen_string_literal: true

require 'net/http'
require 'uri'
require_relative '../../lib/trading/xai_client'
require_relative '../support/xai_har_fixtures'

module XaiClientSpecHelpers
  include XaiHarFixtures

  def archiver
    @archiver ||= Trading::HarArchiver.new
  end

  def client
    @client ||= Trading::XaiClient.new(api_key: 'test-key', har_archiver: archiver)
  end

  def fake_http
    @fake_http ||= instance_double(Net::HTTP).tap do |http|
      allow(http).to receive(:read_timeout=)
      allow(http).to receive(:open_timeout=)
    end
  end

  def stub_http!
    allow(Net::HTTP).to receive(:start) { |*_args, &block| block.call(fake_http) }
  end

  def post_call
    client.post(input: [], tools: [], tool_choice: 'auto')
  end

  def stub_attempts(error: Net::ReadTimeout, fail_first: 0)
    @calls = 0
    allow(fake_http).to receive(:request) do
      @calls += 1
      @calls <= fail_first ? raise(error) : stub_response
    end
  end
end

describe Trading::XaiClient, 'timeout configuration' do
  include XaiClientSpecHelpers

  before { stub_http! }

  it 'sets a 2-minute read timeout on the HTTP connection' do
    expect(fake_http).to receive(:read_timeout=).with(120)
    allow(fake_http).to receive(:request).and_return(stub_response)
    post_call
  end

  it 'sets a 2-minute open timeout on the HTTP connection' do
    expect(fake_http).to receive(:open_timeout=).with(120)
    allow(fake_http).to receive(:request).and_return(stub_response)
    post_call
  end
end

describe Trading::XaiClient, 'retry on timeout' do
  include XaiClientSpecHelpers

  before { stub_http! }

  it 'retries up to five times when the server does not respond' do
    stub_attempts(fail_first: 4)
    expect { post_call }.not_to raise_error
    expect(@calls).to eq(5)
  end

  it 'treats Net::OpenTimeout the same as Net::ReadTimeout' do
    stub_attempts(error: Net::OpenTimeout, fail_first: 2)
    post_call
    expect(@calls).to eq(3)
  end

  it 'raises ServiceError after five consecutive timeouts' do
    stub_attempts(fail_first: Float::INFINITY)
    expect { post_call }.to raise_error(Trading::ServiceError, /5 attempts/)
    expect(@calls).to eq(5)
  end

  it 'does not retry on non-timeout exceptions' do
    stub_attempts(error: RuntimeError, fail_first: Float::INFINITY)
    expect { post_call }.to raise_error(RuntimeError)
    expect(@calls).to eq(1)
  end
end

describe Trading::XaiClient, 'archiving and parsing' do
  include XaiClientSpecHelpers

  before { stub_http! }

  it 'archives only the successful attempt, not timed-out attempts' do
    calls = 0
    allow(fake_http).to receive(:request) do
      calls += 1
      calls < 3 ? raise(Net::ReadTimeout) : stub_response
    end
    post_call
    expect(JSON.parse(File.read(archiver.filepath))['log']['entries'].size).to eq(1)
  end

  it 'returns the parsed JSON body on success' do
    allow(fake_http).to receive(:request).and_return(stub_response)
    expect(post_call).to eq('output' => 'hello')
  end
end
