# frozen_string_literal: true

require_relative '../../lib/har_archiver'

describe Trading::HarArchiver, 'persistence' do
  it 'persists progressively so each append leaves a valid HAR on disk' do
    archiver = Trading::HarArchiver.new
    start_time = Time.now
    archiver.append(har_request_data, har_response_data, start_time, start_time + 0.1)
    expect(JSON.parse(File.read(archiver.filepath))['log']['entries'].size).to eq(1)

    archiver.append(alt_request_data, alt_response_data, start_time + 0.2, start_time + 0.3)
    expect(JSON.parse(File.read(archiver.filepath))['log']['entries'].size).to eq(2)
  end

  it 'honors a caller-supplied filepath' do
    custom = File.expand_path('../../output/custom_session.har', __dir__)
    File.delete(custom) if File.exist?(custom)
    instance = Trading::HarArchiver.new(filepath: custom)
    start_time = Time.now
    instance.append(har_request_data, har_response_data, start_time, start_time + 0.05)
    expect(instance.filepath).to eq(custom)
    expect(File.exist?(custom)).to be true
  ensure
    File.delete(custom) if custom && File.exist?(custom)
  end
end
