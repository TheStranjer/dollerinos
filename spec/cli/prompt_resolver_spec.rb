# frozen_string_literal: true

require 'stringio'
require_relative '../../lib/cli/prompt_resolver'

module PromptResolverHelpers
  def resolve_with(env:, input: StringIO.new, output: StringIO.new)
    Cli::PromptResolver.resolve(env: env, input: input, output: output)
  end
end

RSpec.configure { |c| c.include PromptResolverHelpers }

describe Cli::PromptResolver, 'env var present' do
  it 'returns the DOLLERINOS_PROMPT value when set' do
    expect(resolve_with(env: { 'DOLLERINOS_PROMPT' => 'Buy AAPL' })).to eq('Buy AAPL')
  end

  it 'strips surrounding whitespace from the env var' do
    expect(resolve_with(env: { 'DOLLERINOS_PROMPT' => "  hello\n" })).to eq('hello')
  end

  it 'does not prompt interactively when the env var is populated' do
    output = StringIO.new
    resolve_with(env: { 'DOLLERINOS_PROMPT' => 'preset' }, output: output)
    expect(output.string).to eq('')
  end
end

describe Cli::PromptResolver, 'env var blank, fallback to stdin' do
  it 'falls back to stdin when the env var is missing' do
    expect(resolve_with(env: {}, input: StringIO.new("Custom query\n"))).to eq('Custom query')
  end

  it 'falls back to stdin when the env var is empty' do
    expect(resolve_with(env: { 'DOLLERINOS_PROMPT' => '' }, input: StringIO.new("typed\n"))).to eq('typed')
  end

  it 'falls back to stdin when the env var is whitespace only' do
    expect(resolve_with(env: { 'DOLLERINOS_PROMPT' => '   ' }, input: StringIO.new("real\n"))).to eq('real')
  end
end

describe Cli::PromptResolver, 'no prompt available' do
  it 'returns nil when the env var is blank and stdin input is also blank' do
    expect(resolve_with(env: {}, input: StringIO.new("\n"))).to be_nil
  end

  it 'returns nil when the env var is blank and stdin is closed' do
    expect(resolve_with(env: {}, input: StringIO.new(''))).to be_nil
  end

  it 'writes the request message to output when prompting interactively' do
    output = StringIO.new
    resolve_with(env: {}, input: StringIO.new("anything\n"), output: output)
    expect(output.string).to include('Enter a prompt')
  end
end
