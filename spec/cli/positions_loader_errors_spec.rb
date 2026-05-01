# frozen_string_literal: true

require 'tempfile'
require_relative '../../lib/cli/positions_loader'

describe Cli::PositionsLoader, 'error handling' do
  def with_tempfile(contents)
    temp = Tempfile.new('positions.json')
    temp.write(contents)
    temp.close
    yield(temp.path)
  ensure
    temp&.unlink
  end

  it 'raises when the file does not exist' do
    expect { described_class.new('/nope.json').load }.to raise_error(/not found/)
  end

  it 'raises on malformed JSON' do
    with_tempfile('{ broken') { |path| expect { described_class.new(path).load }.to raise_error(/Invalid JSON/) }
  end

  it 'raises when JSON is not an array' do
    with_tempfile('{}') do |path|
      expect { described_class.new(path).load }.to raise_error(/JSON array/)
    end
  end
end
