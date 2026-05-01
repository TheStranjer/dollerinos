# frozen_string_literal: true

require_relative '../../lib/cli/format_helpers'

describe Cli::FormatHelpers, '.format_price' do
  it 'formats prices >= 1 with two decimals' do
    expect(described_class.format_price(150.25)).to eq('$150.25')
  end

  it 'formats prices < 1 with four decimals' do
    expect(described_class.format_price(0.0123)).to eq('$0.0123')
  end

  it 'returns N/A for nil' do
    expect(described_class.format_price(nil)).to eq('N/A')
  end
end
