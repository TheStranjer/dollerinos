# frozen_string_literal: true

require_relative '../../lib/har_archiver'

describe Trading::HarArchiver, 'file creation' do
  before { Dir.glob(File.expand_path('../../output/*.har', __dir__)).each { |f| File.delete(f) } }

  it 'writes a HAR file under output/ with a grok_ prefix' do
    filepath = archive_now
    expect(File.exist?(filepath)).to be true
    expect(filepath).to include('output/grok_').and end_with('.har')
  end

  it 'generates timestamp-based filenames that change between runs' do
    first = archive_now
    sleep 0.01
    second = archive_now
    expect(first).not_to eq(second)
  end
end
