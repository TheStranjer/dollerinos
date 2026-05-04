# frozen_string_literal: true

require_relative '../../lib/cli/recommender'

module RecommenderHelpers
  def sample_trade
    Trading::Trade.new(type: 'stock', symbol: 'AAPL', min_price: 150, max_price: 160,
                       confidence: 75, reasoning: 'good', position_type: 'buy')
  end

  def stub_service_with(result)
    fake_service = instance_double(Trading::GrokTradeService, call: result)
    allow(Trading::GrokTradeService).to receive(:new).and_return(fake_service)
    fake_service
  end

  def silence_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end
end

RSpec.configure { |c| c.include RecommenderHelpers }

describe Cli::Recommender, 'exit codes' do
  it 'returns 0 and renders trades on success' do
    stub_service_with(Trading::Result.new(trades: [sample_trade]))
    code = silence_stdout { described_class.new(5000).run }
    expect(code).to eq(0)
  end

  it 'returns 1 and renders the error on failure' do
    stub_service_with(Trading::Result.new(trades: [], error_message: 'API error'))
    code = silence_stdout { described_class.new(5000).run }
    expect(code).to eq(1)
  end
end

describe Cli::Recommender, 'user_prompt forwarding' do
  it 'passes the user_prompt option through to the service' do
    fake_service = instance_double(Trading::GrokTradeService, call: Trading::Result.new(trades: [sample_trade]))
    expect(Trading::GrokTradeService).to receive(:new).with(
      hash_including(user_prompt: 'Focus on tech')
    ).and_return(fake_service)
    silence_stdout { described_class.new(5000, user_prompt: 'Focus on tech').run }
  end

  it 'defaults user_prompt to nil when not provided' do
    fake_service = instance_double(Trading::GrokTradeService, call: Trading::Result.new(trades: [sample_trade]))
    expect(Trading::GrokTradeService).to receive(:new).with(
      hash_including(user_prompt: nil)
    ).and_return(fake_service)
    silence_stdout { described_class.new(5000).run }
  end
end
