# frozen_string_literal: true

require_relative '../../lib/har_archiver'

# Synthetic test secrets only — never real credentials.
FAKE_XAI_KEY = 'xai-fake-test-key-1234567890'
FAKE_UW_KEY = 'uw-fake-test-secret-abcdef'

describe Trading::HarArchiver, 'scrubs configured sensitive values from request side' do
  let(:archiver) { Trading::HarArchiver.new(sensitive_values: [FAKE_XAI_KEY, FAKE_UW_KEY]) }

  it 'redacts a sensitive value embedded in the request URL' do
    request = har_request_data.merge(url: "https://api.example.com/v1?token=#{FAKE_XAI_KEY}")
    archiver.append(request, har_response_data, Time.now, Time.now + 0.01)
    entry = JSON.parse(File.read(archiver.filepath))['log']['entries'][0]
    expect(entry['request']['url']).to eq('https://api.example.com/v1?token=[REDACTED]')
  end

  it 'redacts a sensitive value that leaks into a request body' do
    request = har_request_data.merge(body: %({"api_key":"#{FAKE_UW_KEY}","x":1}))
    archiver.append(request, har_response_data, Time.now, Time.now + 0.01)
    contents = File.read(archiver.filepath)
    expect(contents).not_to include(FAKE_UW_KEY)
    expect(contents).to include('[REDACTED]')
  end
end

describe Trading::HarArchiver, 'scrubs configured sensitive values from response side' do
  let(:archiver) { Trading::HarArchiver.new(sensitive_values: [FAKE_XAI_KEY]) }

  it 'redacts a sensitive value echoed back in a response body' do
    response = har_response_data.merge(body: %({"echo":"#{FAKE_XAI_KEY}"}))
    archiver.append(har_request_data, response, Time.now, Time.now + 0.01)
    expect(File.read(archiver.filepath)).not_to include(FAKE_XAI_KEY)
  end

  it 'redacts a sensitive value that surfaces in an unrelated response header' do
    response = har_response_data.merge(headers: [{ name: 'X-Trace', value: "traced=#{FAKE_XAI_KEY}" }])
    archiver.append(har_request_data, response, Time.now, Time.now + 0.01)
    entry = JSON.parse(File.read(archiver.filepath))['log']['entries'][0]
    trace = entry['response']['headers'].find { |header| header['name'] == 'X-Trace' }
    expect(trace['value']).to eq('traced=[REDACTED]')
  end

  it 'ignores empty, nil, and short sensitive values' do
    permissive = Trading::HarArchiver.new(sensitive_values: [nil, '', 'short'])
    request = har_request_data.merge(body: '{"keep":"short"}')
    permissive.append(request, har_response_data, Time.now, Time.now + 0.01)
    entry = JSON.parse(File.read(permissive.filepath))['log']['entries'][0]
    expect(entry['request']['postData']['text']).to eq('{"keep":"short"}')
  end
end
