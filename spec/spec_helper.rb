# frozen_string_literal: true

require 'rspec'
require 'json'
require 'time'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string'

Dir[File.expand_path('support/**/*.rb', __dir__)].each { |path| require path }

RSpec.configure do |config|
  config.include GrokTradeFixtures
  config.include StdoutCapture
  config.include HarFixtures
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
