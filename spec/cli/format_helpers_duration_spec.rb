# frozen_string_literal: true

require_relative '../../lib/cli/format_helpers'

describe Cli::FormatHelpers, '.format_duration' do
  it 'renders hours/minutes/seconds compactly' do
    expect(described_class.format_duration(3_661_000)).to eq('1hr 1min 1s')
  end

  it 'falls back to whole seconds when smaller than a minute' do
    expect(described_class.format_duration(0)).to eq('0s')
  end
end

describe Cli::FormatHelpers, '.format_number and .confidence_indicator' do
  it 'inserts thousands separators' do
    expect(Cli::FormatHelpers.format_number(1_234_567)).to eq('1,234,567')
  end

  it 'fills 10 bars at 100% confidence' do
    expect(Cli::FormatHelpers.confidence_indicator(100)).to include('█' * 10)
  end

  it 'fills 5 bars at 50% confidence' do
    expect(Cli::FormatHelpers.confidence_indicator(50)).to include('█' * 5).and include('░' * 5)
  end
end
