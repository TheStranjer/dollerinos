# frozen_string_literal: true

require_relative '../../lib/har_archiver'

describe Trading::HarArchiver, 'handles missing header collections' do
  let(:archiver) { Trading::HarArchiver.new }
  let(:start_time) { Time.now }

  it 'returns an empty header array when the request supplies no headers' do
    request = har_request_data.merge(headers: nil)
    archiver.append(request, har_response_data, start_time, start_time + 0.1)
    entry = JSON.parse(File.read(archiver.filepath))['log']['entries'][0]
    expect(entry['request']['headers']).to eq([])
  end

  it 'returns an empty header array when the response supplies no headers' do
    response = har_response_data.merge(headers: nil)
    archiver.append(har_request_data, response, start_time, start_time + 0.1)
    entry = JSON.parse(File.read(archiver.filepath))['log']['entries'][0]
    expect(entry['response']['headers']).to eq([])
  end
end
