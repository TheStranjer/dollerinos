# frozen_string_literal: true

require_relative '../../lib/har_archiver'

describe Trading::HarArchiver, 'response and timing' do
  let(:entry) { JSON.parse(File.read(archive_now))['log']['entries'][0] }

  it 'records response status, status text, and body' do
    expect(entry['response']['status']).to eq(200)
    expect(entry['response']['statusText']).to eq('OK')
    expect(entry['response']['content']['text']).to eq('{"result": "success"}')
  end

  it 'records timing information' do
    expect(entry['timings']).to have_key('wait')
    expect(entry['time']).to match(/\d+ms/)
  end
end
