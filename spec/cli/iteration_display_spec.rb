# frozen_string_literal: true

require 'stringio'
require_relative '../../lib/cli/iteration_display'
require_relative '../../lib/cli/styles'

module IterationDisplayHelpers
  def render_to_string(items, tool_results: [])
    original = $stdout
    $stdout = StringIO.new
    Cli::IterationDisplay.new(Cli::Styles.palette).render(
      iteration: 1, max_iterations: 10, output_items: items, tool_results: tool_results
    )
    $stdout.string
  ensure
    $stdout = original
  end
end

RSpec.configure { |c| c.include IterationDisplayHelpers }

describe Cli::IterationDisplay, 'web_search_call rendering' do
  it 'shows the web_search action and query' do
    item = {
      'type' => 'web_search_call',
      'action' => { 'type' => 'search', 'query' => 'AAPL earnings beat' }
    }

    output = render_to_string([item])

    expect(output).to include('web_search')
    expect(output).to include('AAPL earnings beat')
  end

  it 'omits the query line when no query is present' do
    output = render_to_string([{ 'type' => 'web_search_call', 'action' => {} }])

    expect(output).to include('web_search')
    expect(output).not_to include('query:')
  end
end

describe Cli::IterationDisplay, 'custom_tool_call rendering' do
  it 'shows the tool name and pretty-printed input arguments' do
    item = {
      'type' => 'custom_tool_call',
      'name' => 'x_keyword_search',
      'input' => '{"query":"PLTR squeeze","limit":"10"}'
    }

    output = render_to_string([item])

    expect(output).to include('x_keyword_search')
    expect(output).to include('PLTR squeeze')
  end
end

describe Cli::IterationDisplay, 'function_call rendering for hellthread' do
  it 'still renders namespaced hellthread function_calls' do
    item = {
      'type' => 'function_call',
      'name' => 'hellthread__fourChanCatalog',
      'arguments' => '{"board":"biz"}'
    }

    output = render_to_string([item])

    expect(output).to include('hellthread__fourChanCatalog')
    expect(output).to include('biz')
  end
end
