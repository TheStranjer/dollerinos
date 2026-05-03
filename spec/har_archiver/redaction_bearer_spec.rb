# frozen_string_literal: true

require_relative '../../lib/har_archiver'

describe Trading::HarArchiver, 'redacts Bearer Authorization headers' do
  let(:archiver) { Trading::HarArchiver.new }

  it 'redacts a Bearer token in request Authorization headers' do
    entry = archive_entry(archiver, request_headers: [
                            { name: 'Authorization', value: 'Bearer 12344-abcd-34345' }
                          ])
    expect(entry['request']['headers'].first['value']).to eq('Bearer [REDACTED]')
  end

  it 'redacts a Bearer token in response Authorization headers' do
    entry = archive_entry(archiver, response_headers: [
                            { name: 'authorization', value: 'Bearer secret-grok-token' }
                          ])
    expect(entry['response']['headers'].first['value']).to eq('Bearer [REDACTED]')
  end

  it 'matches Authorization header names case-insensitively' do
    entry = archive_entry(archiver, request_headers: [
                            { name: 'AUTHORIZATION', value: 'Bearer unusual-whales-key' }
                          ])
    expect(entry['request']['headers'].first['value']).to eq('Bearer [REDACTED]')
  end
end
