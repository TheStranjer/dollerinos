# frozen_string_literal: true

require_relative '../../lib/cli/option_card'
require_relative '../../lib/cli/styles'
require_relative '../../lib/grok_trade_service'

describe Cli::OptionCard do
  let(:trade) do
    Trading::Trade.new(
      type: 'option', symbol: 'TSLA', min_price: 3.0, max_price: 7.0,
      confidence: 60, reasoning: 'Bullish setup', strike_price: 250.0,
      expiration_date_min: '2026-05-15', expiration_date_max: '2026-05-22',
      option_type: 'call', position_type: 'buy'
    )
  end

  def render(target = trade)
    capture_stdout { described_class.new(Cli::Styles.palette).render(target, 1) }
  end

  it 'shows symbol, option type, BUY, strike, premium, expiration, confidence, thesis' do
    rendered = render
    expect(rendered).to include('TSLA').and include('CALL').and include('BUY')
    expect(rendered).to include('$250').and include('$3').and include('$7')
    expect(rendered).to include('2026-05-15').and include('Bullish setup')
  end

  it 'falls back to N/A when expiration or strike is missing' do
    bare = Trading::Trade.new(type: 'option', symbol: 'SPY', min_price: 1, max_price: 2,
                              confidence: 30, reasoning: 'x', option_type: 'put', position_type: 'sell')
    expect(render(bare)).to include('N/A')
  end
end
