# frozen_string_literal: true

require_relative '../../lib/cli/stock_card'
require_relative '../../lib/cli/styles'
require_relative '../../lib/grok_trade_service'

describe Cli::StockCard do
  let(:trade) do
    Trading::Trade.new(
      type: 'stock', symbol: 'AAPL', min_price: 150.0, max_price: 160.0,
      confidence: 75, reasoning: 'Strong fundamentals', position_type: 'buy'
    )
  end

  def render
    capture_stdout { described_class.new(Cli::Styles.palette).render(trade, 1) }
  end

  it 'shows symbol, price range, confidence, thesis, and BUY action' do
    rendered = render
    expect(rendered).to include('AAPL').and include('BUY').and include('75%')
    expect(rendered).to include('$150').and include('$160').and include('Strong fundamentals')
  end
end
