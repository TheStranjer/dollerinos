# frozen_string_literal: true

require_relative '../../lib/har_archiver'

describe Trading::HarArchiver, 'multi-entry session' do
  let(:archiver) { Trading::HarArchiver.new }

  it 'collects multiple appends into a single HAR file' do
    start_time = Time.now
    archiver.append(har_request_data, har_response_data, start_time, start_time + 0.1)
    archiver.append(alt_request_data, alt_response_data, start_time + 0.2, start_time + 0.4)

    entries = JSON.parse(File.read(archiver.filepath))['log']['entries']
    expect(entries.size).to eq(2)
    expect(entries[0]['request']['postData']['text']).to eq('{"test": "data"}')
    expect(entries[1]['request']['postData']['text']).to eq('{"test": "second"}')
    expect(entries[1]['response']['content']['text']).to eq('{"result": "again"}')
  end

  it 'tracks the entry count' do
    start_time = Time.now
    expect(archiver.entry_count).to eq(0)
    archiver.append(har_request_data, har_response_data, start_time, start_time + 0.1)
    archiver.append(har_request_data, har_response_data, start_time, start_time + 0.1)
    expect(archiver.entry_count).to eq(2)
  end
end
