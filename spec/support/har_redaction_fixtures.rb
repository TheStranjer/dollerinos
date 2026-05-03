# frozen_string_literal: true

# Shared helpers for HAR Authorization-redaction specs.
module HarRedactionFixtures
  def archive_entry(archiver, request_headers: [], response_headers: [])
    request = har_request_data.merge(headers: request_headers)
    response = har_response_data.merge(headers: response_headers)
    start_time = Time.now
    archiver.append(request, response, start_time, start_time + 0.1)
    JSON.parse(File.read(archiver.filepath))['log']['entries'][0]
  end
end
