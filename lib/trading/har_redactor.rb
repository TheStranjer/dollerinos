# frozen_string_literal: true

module Trading
  # Removes credentials and other configured secrets from header lists, URLs,
  # and body text before they reach the HAR file on disk.
  class HarRedactor
    AUTHORIZATION_HEADER = /\Aauthorization\z/i
    BEARER_AUTHORIZATION = /\ABearer\s+\S+/
    REDACTED_BEARER = 'Bearer [REDACTED]'
    REDACTED_VALUE = '[REDACTED]'
    SENSITIVE_HEADER = /
      \A(?:authorization|proxy-authorization|x-api-key|api-key|
           x-auth-token|cookie|set-cookie)\z
    /xi
    MIN_SENSITIVE_VALUE_LENGTH = 8

    def initialize(sensitive_values: [])
      @sensitive_values = filter_sensitive_values(sensitive_values)
    end

    def headers(headers)
      return [] unless headers

      headers.each_with_object([]) do |header, redacted|
        sanitized = sanitize_header(header)
        redacted << sanitized if sanitized
      end
    end

    def scrub(text)
      return text if text.nil? || @sensitive_values.empty?

      @sensitive_values.reduce(text) { |memo, secret| memo.gsub(secret, REDACTED_VALUE) }
    end

    private

    def filter_sensitive_values(values)
      Array(values).compact.map(&:to_s)
                   .reject(&:empty?)
                   .select { |value| value.length >= MIN_SENSITIVE_VALUE_LENGTH }
                   .uniq
    end

    def sanitize_header(header)
      name = header[:name].to_s
      value = header[:value].to_s
      return scrub_header_value(header, value) unless name.match?(SENSITIVE_HEADER)
      return header.merge(value: REDACTED_BEARER) if bearer_authorization?(name, value)
      return nil if name.match?(AUTHORIZATION_HEADER)

      header.merge(value: REDACTED_VALUE)
    end

    def bearer_authorization?(name, value)
      name.match?(AUTHORIZATION_HEADER) && value.match?(BEARER_AUTHORIZATION)
    end

    def scrub_header_value(header, value)
      scrubbed = scrub(value)
      scrubbed.equal?(value) ? header : header.merge(value: scrubbed)
    end
  end
end
