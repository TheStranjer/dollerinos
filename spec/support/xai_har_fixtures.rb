# frozen_string_literal: true

require 'net/http'
require 'uri'

# Shared Net::HTTP request/response stubs for XaiHarArchiver and XaiClient specs.
module XaiHarFixtures
  def stub_request
    Net::HTTP::Post.new(URI(Trading::Constants::XAI_RESPONSES_URL)).tap do |req|
      req['Content-Type'] = 'application/json'
      req['Authorization'] = 'Bearer test-key'
      req.body = '{"input":"hi"}'
    end
  end

  def stub_response
    Net::HTTPOK.new('1.1', '200', 'OK').tap do |res|
      res['content-type'] = 'application/json'
      res.instance_variable_set(:@body, '{"output":"hello"}')
      res.instance_variable_set(:@read, true)
    end
  end
end
