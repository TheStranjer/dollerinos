# frozen_string_literal: true

# Shared request/response fixtures for HarArchiver specs.
module HarFixtures
  def har_request_data
    {
      method: 'POST',
      url: 'https://api.x.ai/v1/responses',
      headers: [{ name: 'Content-Type', value: 'application/json' }],
      body: '{"test": "data"}'
    }
  end

  def har_response_data
    {
      code: 200, message: 'OK',
      headers: [{ name: 'content-type', value: 'application/json' }],
      content_type: 'application/json', body: '{"result": "success"}'
    }
  end

  def archive_now
    start_time = Time.now
    Trading::HarArchiver.archive(har_request_data, har_response_data, start_time, start_time + 0.5)
  end
end
