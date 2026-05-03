# frozen_string_literal: true

require_relative '../../lib/har_archiver'

describe Trading::HarArchiver, 'never lets raw provider tokens reach disk' do
  let(:archiver) { Trading::HarArchiver.new }

  it 'redacts Grok, Unusual Whales, and Hellthread Bearer tokens from the persisted HAR' do
    grok = 'xai-grok-12344-abcd-34345'
    unusual_whales = 'uw-live-secret-987'
    hellthread = 'hellthread-pat-deadbeef'
    archive_entry(
      archiver,
      request_headers: [
        { name: 'Authorization', value: "Bearer #{grok}" },
        { name: 'authorization', value: "Bearer #{unusual_whales}" }
      ],
      response_headers: [{ name: 'Authorization', value: "Bearer #{hellthread}" }]
    )
    contents = File.read(archiver.filepath)
    [grok, unusual_whales, hellthread].each { |token| expect(contents).not_to include(token) }
    expect(contents).to include('Bearer [REDACTED]')
  end
end
