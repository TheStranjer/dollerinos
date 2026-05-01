# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::Trade do
  def build(**overrides)
    described_class.new(
      **{ type: 'stock', symbol: 'AAPL', min_price: 1, max_price: 2, confidence: 50, reasoning: 'x' }.merge(overrides)
    )
  end

  it 'accepts a valid stock trade' do
    expect(build).to be_valid
  end

  it 'rejects an unsupported type' do
    expect(build(type: 'futures')).not_to be_valid
  end

  it 'rejects when min_price exceeds max_price' do
    expect(build(min_price: 5, max_price: 1)).not_to be_valid
  end

  it 'rejects an out-of-range confidence' do
    expect(build(confidence: 150)).not_to be_valid
  end

  it 'classifies stocks and options' do
    expect(build(type: 'stock')).to be_stock
    expect(build(type: 'option')).to be_option
  end
end
