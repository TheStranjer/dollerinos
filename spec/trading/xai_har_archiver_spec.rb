# frozen_string_literal: true

require 'net/http'
require 'uri'
require_relative '../../lib/trading/xai_har_archiver'
require_relative '../support/xai_har_fixtures'

describe Trading::XaiHarArchiver do
  include XaiHarFixtures

  let(:archiver) { Trading::HarArchiver.new }

  it 'appends a request/response pair to the shared archiver' do
    start_time = Time.now
    described_class.append(
      archiver: archiver, request: stub_request, response: stub_response,
      start_time: start_time, end_time: start_time + 0.1
    )

    entries = JSON.parse(File.read(archiver.filepath))['log']['entries']
    expect(entries.size).to eq(1)
    expect(entries[0]['request']['url']).to eq(Trading::Constants::XAI_RESPONSES_URL)
    expect(entries[0]['response']['content']['text']).to eq('{"output":"hello"}')
  end

  it 'unifies multiple xAI exchanges into a single HAR file' do
    start_time = Time.now
    2.times do |i|
      described_class.append(
        archiver: archiver, request: stub_request, response: stub_response,
        start_time: start_time + i, end_time: start_time + i + 0.1
      )
    end

    expect(JSON.parse(File.read(archiver.filepath))['log']['entries'].size).to eq(2)
  end
end
