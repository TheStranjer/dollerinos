#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup' if File.exist?(File.expand_path('../Gemfile', __dir__))
require_relative '../lib/cli/prompt_resolver'
require_relative '../lib/cli/recommender'

USAGE = <<~USAGE.freeze
  Usage: #{$PROGRAM_NAME} <liquidity_amount> [positions_file]

  Arguments:
    liquidity_amount  - Amount of capital available for trading (required)
    positions_file    - Path to JSON file with current positions (optional)

  Examples:
    #{$PROGRAM_NAME} 10000
    #{$PROGRAM_NAME} 10000 positions.json
USAGE

def parse_amount(raw)
  amount = Float(raw)
  raise 'Liquidity amount must be positive' if amount <= 0

  amount
end

def main
  if ARGV.empty? || ARGV.length > 2
    puts USAGE
    exit(1)
  end

  amount = parse_amount(ARGV[0])
  user_prompt = Cli::PromptResolver.resolve
  exit(Cli::Recommender.new(amount, positions_file: ARGV[1], user_prompt: user_prompt).run)
rescue StandardError => e
  puts "Error: #{e.message}"
  exit(1)
end

main if $PROGRAM_NAME == __FILE__
