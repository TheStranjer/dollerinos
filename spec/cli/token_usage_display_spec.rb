# frozen_string_literal: true

require_relative '../../lib/cli/styles'
require_relative '../../lib/cli/token_usage_display'

describe Cli::TokenUsageDisplay do
  let(:palette) { Cli::Styles.palette }

  def render(usage, duration_ms = 0)
    output = StringIO.new
    $stdout = output
    described_class.new(palette).render(usage, duration_ms)
    output.string
  ensure
    $stdout = STDOUT
  end

  it 'shows input, output, and total token counts' do
    rendered = render({ 'input_tokens' => 100, 'output_tokens' => 50 })
    expect(rendered).to include('Input Tokens:').and include('100')
    expect(rendered).to include('Output Tokens:').and include('50')
    expect(rendered).to include('Total Tokens:').and include('150')
  end

  it 'shows reasoning tokens only when positive' do
    rendered = render({ 'input_tokens' => 1, 'output_tokens' => 1, 'reasoning_tokens' => 7 })
    expect(rendered).to include('Reasoning Tokens:').and include('7')
  end

  it 'shows resolution time when duration is positive' do
    rendered = render({ 'input_tokens' => 1, 'output_tokens' => 1 }, 90_000)
    expect(rendered).to include('Resolution Time:').and include('1min')
  end
end
