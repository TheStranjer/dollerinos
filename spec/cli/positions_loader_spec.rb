# frozen_string_literal: true

require 'tempfile'
require 'json'
require_relative '../../lib/cli/positions_loader'

describe Cli::PositionsLoader do
  def with_tempfile(contents)
    temp = Tempfile.new('positions.json')
    temp.write(contents)
    temp.close
    yield(temp.path)
  ensure
    temp&.unlink
  end

  it 'loads and normalizes positions' do
    data = [{ 'type' => 'option', 'symbol' => 'tsla', 'quantity' => 5, 'position_type' => 'long',
              'option_type' => 'CALL' }]
    with_tempfile(JSON.generate(data)) do |path|
      positions = described_class.new(path).load
      expect(positions.first.symbol).to eq('TSLA')
      expect(positions.first.option_type).to eq('call')
    end
  end
end
