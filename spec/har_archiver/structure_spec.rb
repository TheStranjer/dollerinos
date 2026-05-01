# frozen_string_literal: true

require_relative '../../lib/har_archiver'

describe Trading::HarArchiver, 'HAR structure' do
  let(:har_data) { JSON.parse(File.read(archive_now)) }

  it 'has a top-level log with version, creator, and entries' do
    expect(har_data).to have_key('log')
    expect(har_data['log']).to include('version', 'creator', 'entries')
  end

  it 'records request method, url, headers, and post body' do
    request = har_data['log']['entries'][0]['request']
    expect(request['method']).to eq('POST')
    expect(request['url']).to eq('https://api.x.ai/v1/responses')
    expect(request['headers']).to be_an(Array)
    expect(request['postData']['text']).to eq('{"test": "data"}')
  end
end
