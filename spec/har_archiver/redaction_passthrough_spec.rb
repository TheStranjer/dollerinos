# frozen_string_literal: true

require_relative '../../lib/har_archiver'

describe Trading::HarArchiver, 'leaves non-Authorization headers untouched' do
  let(:archiver) { Trading::HarArchiver.new }

  it 'preserves arbitrary request headers verbatim' do
    entry = archive_entry(archiver, request_headers: [
                            { name: 'Content-Type', value: 'application/json' },
                            { name: 'X-Hellthread-Trace', value: 'trace-123' }
                          ])
    expect(entry['request']['headers']).to eq([
                                                { 'name' => 'Content-Type', 'value' => 'application/json' },
                                                { 'name' => 'X-Hellthread-Trace', 'value' => 'trace-123' }
                                              ])
  end
end
