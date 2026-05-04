# frozen_string_literal: true

require_relative '../../lib/har_archiver'

describe Trading::HarArchiver, 'binary-tagged UTF-8 bodies' do
  let(:archiver) { Trading::HarArchiver.new }
  let(:utf8_payload) { "{\"greeting\":\"hello \u{1F600}\"}" }
  let(:binary_body) { utf8_payload.dup.force_encoding(Encoding::ASCII_8BIT) }

  def append_binary
    start_time = Time.now
    request = har_request_data.merge(body: binary_body)
    response = har_response_data.merge(body: binary_body)
    archiver.append(request, response, start_time, start_time + 0.05)
  end

  it 'persists ASCII-8BIT-tagged UTF-8 bodies without JSON encoding warnings' do
    expect { append_binary }.not_to output(/UTF-8 string passed as BINARY/).to_stderr
  end

  it 'round-trips the original bytes through the persisted HAR file' do
    append_binary
    entry = JSON.parse(File.read(archiver.filepath))['log']['entries'][0]
    expect(entry['request']['postData']['text']).to eq(utf8_payload)
    expect(entry['response']['content']['text']).to eq(utf8_payload)
  end
end
