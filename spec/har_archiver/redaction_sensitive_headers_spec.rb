# frozen_string_literal: true

require_relative '../../lib/har_archiver'

describe Trading::HarArchiver, 'redacts api-key style request headers' do
  let(:archiver) { Trading::HarArchiver.new }

  it 'redacts X-API-Key on requests' do
    entry = archive_entry(archiver, request_headers: [
                            { name: 'X-API-Key', value: 'fake-test-api-key-abc123' }
                          ])
    expect(entry['request']['headers']).to eq([
                                                { 'name' => 'X-API-Key', 'value' => '[REDACTED]' }
                                              ])
  end

  it 'redacts api-key, x-auth-token, and proxy-authorization headers' do
    entry = archive_entry(archiver, request_headers: [
                            { name: 'api-key', value: 'fake-1' },
                            { name: 'X-Auth-Token', value: 'fake-2' },
                            { name: 'Proxy-Authorization', value: 'Basic fake' }
                          ])
    values = entry['request']['headers'].map { |header| header['value'] }
    expect(values).to eq(['[REDACTED]', '[REDACTED]', '[REDACTED]'])
  end
end

describe Trading::HarArchiver, 'redacts cookie-style headers and matches case-insensitively' do
  let(:archiver) { Trading::HarArchiver.new }

  it 'redacts Cookie request headers and Set-Cookie response headers' do
    entry = archive_entry(
      archiver,
      request_headers: [{ name: 'Cookie', value: 'session=abc; uid=42' }],
      response_headers: [{ name: 'set-cookie', value: '__cf_bm=token; Path=/' }]
    )
    expect(entry['request']['headers'].first['value']).to eq('[REDACTED]')
    expect(entry['response']['headers'].first['value']).to eq('[REDACTED]')
  end

  it 'matches sensitive header names case-insensitively' do
    entry = archive_entry(archiver, request_headers: [
                            { name: 'X-API-KEY', value: 'fake-upper' },
                            { name: 'cookie', value: 'fake-lower' }
                          ])
    expect(entry['request']['headers']).to all(include('value' => '[REDACTED]'))
  end
end
