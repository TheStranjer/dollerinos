# frozen_string_literal: true

require 'json'
require 'net/http'
require_relative 'constants'
require_relative 'structs'
require_relative 'xai_har_archiver'

module Trading
  # Thin wrapper around the xAI /v1/responses endpoint with HAR archiving.
  # Each HTTP attempt is bounded by READ_TIMEOUT; on timeout the request is
  # retried up to MAX_ATTEMPTS times before surfacing a ServiceError.
  class XaiClient
    READ_TIMEOUT = 120
    OPEN_TIMEOUT = 120
    MAX_ATTEMPTS = 5
    URI_OBJECT = URI(Constants::XAI_RESPONSES_URL)
    TIMEOUT_ERRORS = [Net::ReadTimeout, Net::OpenTimeout].freeze

    def initialize(api_key:, har_archiver:)
      @api_key = api_key
      @har_archiver = har_archiver
    end

    def post(input:, tools:, tool_choice:)
      request = build_request(input, tools, tool_choice)
      response = perform_with_retries(request)
      ensure_success(response)
      JSON.parse(response.body)
    end

    private

    def build_request(input, tools, tool_choice)
      request = Net::HTTP::Post.new(URI_OBJECT)
      request['Content-Type'] = 'application/json'
      request['Authorization'] = "Bearer #{@api_key}"
      request.body = body_for(input, tools, tool_choice)
      request
    end

    def body_for(input, tools, tool_choice)
      JSON.generate(model: Constants::MODEL_NAME, input: input, tools: tools, tool_choice: tool_choice)
    end

    def perform_with_retries(request)
      attempt = 0
      begin
        attempt += 1
        perform_and_archive(request)
      rescue *TIMEOUT_ERRORS
        retry if attempt < MAX_ATTEMPTS
        raise ServiceError, "xAI did not respond within #{READ_TIMEOUT}s after #{MAX_ATTEMPTS} attempts."
      end
    end

    def perform_and_archive(request)
      start_time = Time.now
      response = perform(request)
      XaiHarArchiver.append(
        archiver: @har_archiver, request: request, response: response,
        start_time: start_time, end_time: Time.now
      )
      response
    end

    def perform(request)
      Net::HTTP.start(URI_OBJECT.host, URI_OBJECT.port, use_ssl: true) do |http|
        http.read_timeout = READ_TIMEOUT
        http.open_timeout = OPEN_TIMEOUT
        http.request(request)
      end
    end

    def ensure_success(response)
      return if response.is_a?(Net::HTTPSuccess)

      raise ServiceError, "xAI request failed with status #{response.code}."
    end
  end
end
