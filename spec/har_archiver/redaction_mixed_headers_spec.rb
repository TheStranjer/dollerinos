# frozen_string_literal: true

require_relative '../../lib/har_archiver'

describe Trading::HarArchiver, 'redacts only the Authorization header among many' do
  let(:archiver) { Trading::HarArchiver.new }
  let(:redacted) { { 'name' => 'Authorization', 'value' => 'Bearer [REDACTED]' } }

  it 'leaves other headers in place while redacting Authorization on both sides' do
    entry = archive_entry(
      archiver,
      request_headers: [
        { name: 'Content-Type', value: 'application/json' },
        { name: 'Authorization', value: 'Bearer xai-secret' }
      ],
      response_headers: [
        { name: 'content-type', value: 'application/json' },
        { name: 'Authorization', value: 'Bearer reply-secret' }
      ]
    )
    expect(entry['request']['headers']).to include(redacted)
    expect(entry['response']['headers']).to include(redacted)
  end
end
