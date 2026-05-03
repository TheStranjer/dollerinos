# frozen_string_literal: true

require 'json'
require 'time'
require 'fileutils'

module Trading
  # Collects request/response pairs across a single run and persists them to
  # one HTTP Archive (HAR) 1.2 file. Each appended entry overwrites the file
  # in place so partial progress survives a crash mid-run.
  class HarArchiver
    HTTP_VERSION = 'HTTP/1.1'
    OUTPUT_TIMINGS = { blocked: -1, dns: -1, connect: -1, send: -1, receive: -1, ssl: -1 }.freeze

    attr_reader :filepath

    def initialize(filepath: nil)
      @filepath = filepath || default_filepath
      @entries = []
    end

    def append(request_data, response_data, start_time, end_time)
      @entries << build_entry(request_data, response_data, start_time, end_time)
      persist
      @filepath
    end

    def entry_count
      @entries.size
    end

    private

    def persist
      FileUtils.mkdir_p(File.dirname(@filepath))
      File.write(@filepath, JSON.pretty_generate(build_har))
    end

    def build_har
      { log: { version: '1.2', creator: creator, entries: @entries } }
    end

    def creator
      { name: 'grok_trade_service', version: '1.0' }
    end

    def build_entry(request_data, response_data, start_time, end_time)
      duration_ms = ((end_time - start_time) * 1000).round
      {
        startedDateTime: start_time.iso8601,
        time: "#{duration_ms}ms",
        request: build_request_entry(request_data),
        response: build_response_entry(response_data),
        cache: {},
        timings: OUTPUT_TIMINGS.merge(wait: duration_ms)
      }
    end

    def build_request_entry(request_data)
      body_text = request_data[:body]
      {
        method: request_data[:method], url: request_data[:url], httpVersion: HTTP_VERSION,
        headers: request_data[:headers] || [], queryString: [], cookies: [], headersSize: -1,
        bodySize: body_text ? body_text.bytesize : 0,
        postData: body_text ? { mimeType: 'application/json', text: body_text } : nil
      }
    end

    def build_response_entry(response_data)
      body_text = response_data[:body] || ''
      {
        status: response_data[:code], statusText: response_data[:message], httpVersion: HTTP_VERSION,
        headers: response_data[:headers] || [], cookies: [],
        content: build_content(body_text, response_data[:content_type]),
        redirectURL: '', headersSize: -1, bodySize: body_text.bytesize
      }
    end

    def build_content(body_text, content_type)
      { size: body_text.bytesize, compression: 0, mimeType: content_type || 'application/json', text: body_text }
    end

    def default_filepath
      File.expand_path("../output/#{generate_filename}", __dir__)
    end

    def generate_filename
      "grok_#{Time.now.strftime('%Y%m%d_%H%M%S_%L')}.har"
    end
  end
end
