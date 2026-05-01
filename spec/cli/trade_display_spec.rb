# frozen_string_literal: true

require_relative '../../lib/cli/styles'
require_relative '../../lib/cli/trade_display'
require_relative '../../lib/grok_trade_service'

describe Cli::TradeDisplay do
  let(:stock) do
    Trading::Trade.new(type: 'stock', symbol: 'AAPL', min_price: 150, max_price: 160,
                       confidence: 75, reasoning: 'good', position_type: 'buy')
  end
  let(:option) do
    Trading::Trade.new(type: 'option', symbol: 'TSLA', min_price: 3, max_price: 7,
                       confidence: 60, reasoning: 'bullish', strike_price: 250.0,
                       expiration_date_min: '2026-05-15', expiration_date_max: '2026-05-22',
                       option_type: 'call', position_type: 'buy')
  end

  def render(trades)
    capture_stdout { described_class.new(Cli::Styles.palette).render(trades) }
  end

  it 'displays the total recommendation count and STOCKS/OPTIONS sections' do
    rendered = render([stock, option])
    expect(rendered).to include('Total Recommendations: 2').and include('STOCKS').and include('OPTIONS')
  end

  it 'omits sections for empty groups' do
    expect(render([stock])).not_to include('OPTIONS')
  end
end
