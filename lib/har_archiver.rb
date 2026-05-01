require "json"
require "time"
require "fileutils"

module Trading
  class HarArchiver
    def self.archive(request_data, response_data, start_time, end_time)
      new.archive(request_data, response_data, start_time, end_time)
    end

    def archive(request_data, response_data, start_time, end_time)
      har_data = build_har(request_data, response_data, start_time, end_time)
      filename = generate_filename
      filepath = File.expand_path("../output/#{filename}", __dir__)

      FileUtils.mkdir_p(File.dirname(filepath))
      File.write(filepath, JSON.pretty_generate(har_data))

      filepath
    end

    private

    def build_har(request_data, response_data, start_time, end_time)
      duration_ms = ((end_time - start_time) * 1000).round

      {
        log: {
          version: "1.2",
          creator: {
            name: "grok_trade_service",
            version: "1.0"
          },
          entries: [
            {
              startedDateTime: start_time.iso8601,
              time: duration_ms.to_s + "ms",
              request: build_request_entry(request_data),
              response: build_response_entry(response_data),
              cache: {},
              timings: {
                blocked: -1,
                dns: -1,
                connect: -1,
                send: -1,
                wait: duration_ms,
                receive: -1,
                ssl: -1
              }
            }
          ]
        }
      }
    end

    def build_request_entry(request_data)
      body_text = request_data[:body]
      headers = request_data[:headers] || []

      {
        method: request_data[:method],
        url: request_data[:url],
        httpVersion: "HTTP/1.1",
        headers: headers,
        queryString: [],
        cookies: [],
        headersSize: -1,
        bodySize: body_text ? body_text.bytesize : 0,
        postData: body_text ? { mimeType: "application/json", text: body_text } : nil
      }
    end

    def build_response_entry(response_data)
      body_text = response_data[:body] || ""
      headers = response_data[:headers] || []

      {
        status: response_data[:code],
        statusText: response_data[:message],
        httpVersion: "HTTP/1.1",
        headers: headers,
        cookies: [],
        content: {
          size: body_text.bytesize,
          compression: 0,
          mimeType: response_data[:content_type] || "application/json",
          text: body_text
        },
        redirectURL: "",
        headersSize: -1,
        bodySize: body_text.bytesize
      }
    end

    def generate_filename
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S_%L")
      "grok_#{timestamp}.har"
    end
  end
end
