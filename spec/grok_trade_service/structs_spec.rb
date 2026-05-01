# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService do
  describe 'Position struct' do
    it 'supports stock and option holdings' do
      stock = described_class::Position.new(type: 'stock', symbol: 'AAPL', quantity: 100, position_type: 'long')
      option = described_class::Position.new(type: 'option', symbol: 'TSLA', quantity: 5, position_type: 'long',
                                             strike_price: 250.0, expiration_date: '2026-05-15', option_type: 'call')
      expect(stock.symbol).to eq('AAPL')
      expect(option.option_type).to eq('call')
    end
  end

  describe 'Result struct' do
    it 'is success when error_message is blank' do
      expect(described_class::Result.new(trades: [])).to be_success
    end

    it 'is not success when error_message is present' do
      expect(described_class::Result.new(trades: [], error_message: 'boom')).not_to be_success
    end
  end
end
