# frozen_string_literal: true

require_relative '../../lib/har_archiver'

describe Trading::HarArchiver, 'omits non-Bearer Authorization headers' do
  let(:archiver) { Trading::HarArchiver.new }

  it 'drops Basic auth while keeping unrelated headers' do
    entry = archive_entry(archiver, request_headers: [
                            { name: 'Authorization', value: 'Basic dXNlcjpwYXNz' },
                            { name: 'X-Trace', value: 'keep-me' }
                          ])
    names = entry['request']['headers'].map { |h| h['name'] }
    expect(names).to eq(['X-Trace'])
  end

  it 'drops malformed Bearer values' do
    entry = archive_entry(archiver, request_headers: [
                            { name: 'Authorization', value: 'Bearer' },
                            { name: 'Authorization', value: 'Bearer    ' },
                            { name: 'Authorization', value: '' }
                          ])
    expect(entry['request']['headers']).to be_empty
  end
end
