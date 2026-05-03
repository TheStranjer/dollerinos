# frozen_string_literal: true

require_relative '../har_archiver'
require_relative 'constants'

module Trading
  # Builds HAR-format request/response payloads and appends them to a shared
  # session archiver so every xAI exchange in a run lands in one HAR file.
  module XaiHarArchiver
    module_function

    def append(archiver:, request:, response:, start_time:, end_time:)
      archiver.append(
        request_data(request),
        response_data(response),
        start_time,
        end_time
      )
    end

    def request_data(request)
      {
        method: request.method,
        url: Constants::XAI_RESPONSES_URL,
        headers: header_pairs(request),
        body: request.body
      }
    end

    def response_data(response)
      {
        code: response.code.to_i,
        message: response.message,
        headers: header_pairs(response),
        content_type: response['content-type'],
        body: response.body
      }
    end

    def header_pairs(message)
      message.each_header.map { |k, v| { name: k, value: v } }
    end
  end
end
