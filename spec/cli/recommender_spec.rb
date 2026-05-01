# frozen_string_literal: true

require_relative '../../lib/cli/recommender'

describe Cli::Recommender do
  let(:trade) do
    Trading::Trade.new(type: 'stock', symbol: 'AAPL', min_price: 150, max_price: 160,
                       confidence: 75, reasoning: 'good', position_type: 'buy')
  end

  def stub_service_with(result)
    fake_service = instance_double(Trading::GrokTradeService, call: result)
    allow(Trading::GrokTradeService).to receive(:new).and_return(fake_service)
  end

  def silence_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end

  it 'returns 0 and renders trades on success' do
    stub_service_with(Trading::Result.new(trades: [trade]))
    code = silence_stdout { described_class.new(5000).run }
    expect(code).to eq(0)
  end

  it 'returns 1 and renders the error on failure' do
    stub_service_with(Trading::Result.new(trades: [], error_message: 'API error'))
    code = silence_stdout { described_class.new(5000).run }
    expect(code).to eq(1)
  end
end
