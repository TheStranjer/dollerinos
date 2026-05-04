# frozen_string_literal: true

require_relative '../../lib/har_archiver'

describe Trading::HarArchiver, 'file creation' do
  it 'writes a HAR file with a grok_ prefix in the configured output directory' do
    filepath = archive_now
    expect(File.exist?(filepath)).to be true
    expect(File.dirname(filepath)).to eq(ENV.fetch('DOLLERINOS_HAR_OUTPUT_DIR'))
    expect(File.basename(filepath)).to start_with('grok_').and end_with('.har')
  end

  it 'generates timestamp-based filenames that change between runs' do
    first = archive_now
    sleep 0.01
    second = archive_now
    expect(first).not_to eq(second)
  end
end
