# frozen_string_literal: true

require 'rspec'
require 'json'
require 'time'
require 'tmpdir'
require 'fileutils'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string'

Dir[File.expand_path('support/**/*.rb', __dir__)].each { |path| require path }

RSpec.configure do |config|
  config.before(:suite) do
    ENV['DOLLERINOS_HAR_OUTPUT_DIR'] = Dir.mktmpdir('dollerinos-spec-har-')
  end

  config.after(:suite) do
    dir = ENV['DOLLERINOS_HAR_OUTPUT_DIR']
    FileUtils.remove_entry(dir) if dir && File.directory?(dir)
  end

  config.include GrokTradeFixtures
  config.include StdoutCapture
  config.include HarFixtures
  config.include HarRedactionFixtures
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before do |example|
    allow(Kernel).to receive(:sleep) unless example.metadata[:allow_real_sleep]
  end
end
