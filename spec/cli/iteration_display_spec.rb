# frozen_string_literal: true

require 'stringio'
require_relative '../../lib/cli/iteration_display'
require_relative '../../lib/cli/styles'
require_relative '../../lib/trading/constants'

module IterationDisplayHelpers
  def build_display
    io = StringIO.new
    display = Cli::IterationDisplay.new(Cli::Styles.palette, io: io)
    [display, io]
  end

  def gather_tools
    [
      { type: 'web_search' },
      { type: 'x_search' },
      { type: 'function', name: 'hellthread__fourChanCatalog', description: '', parameters: {} },
      { type: 'function', name: 'alpha-vantage__time_series_daily', description: '', parameters: {} }
    ]
  end

  def start_iteration(display, **overrides)
    defaults = {
      iteration: 1, max_iterations: 10, phase: :gather,
      tools: gather_tools, tool_choice: 'required'
    }
    display.iteration_started(**defaults.merge(overrides))
  end
end

RSpec.configure { |c| c.include IterationDisplayHelpers }

describe Cli::IterationDisplay, '#iteration_started header and phase' do
  it 'announces the iteration before any model output is rendered' do
    display, io = build_display
    start_iteration(display, iteration: 3)
    expect(io.string).to include('Starting Iteration 3/10')
  end

  it 'shows the current phase' do
    display, io = build_display
    start_iteration(display)
    expect(io.string).to match(/phase.*gather/)
  end

  it 'shows the tool_choice setting' do
    display, io = build_display
    start_iteration(
      display, phase: :force_trade_recs, tools: [],
               tool_choice: { type: 'function', name: Trading::Constants::FUNCTION_NAME }
    )
    expect(io.string).to include('function:trade_recommendations')
  end
end

describe Cli::IterationDisplay, '#iteration_started tool list' do
  it 'lists every tool exposed to the LLM by name' do
    display, io = build_display
    start_iteration(display)
    expect(io.string).to include('Tools exposed to LLM')
    expect(io.string).to include('web_search')
    expect(io.string).to include('x_search')
    expect(io.string).to include('hellthread__fourChanCatalog')
    expect(io.string).to include('alpha-vantage__time_series_daily')
  end

  it 'shows (none) when the tool list is empty' do
    display, io = build_display
    start_iteration(display, tools: [])
    expect(io.string).to include('(none)')
  end
end

def spying_palette
  Cli::Styles.palette.transform_values do |style|
    spy = instance_double(style.class)
    allow(spy).to receive(:render) { |s| "[styled]#{s}[/]" }
    spy
  end
end

class FlushCountingIO < StringIO
  attr_reader :flush_count

  def initialize
    super
    @flush_count = 0
  end

  def flush
    @flush_count += 1
    super
  end
end

describe Cli::IterationDisplay, '#iteration_started colorization' do
  it 'colorizes the iteration header, phase value, and tool names through the palette' do
    palette = spying_palette
    display = Cli::IterationDisplay.new(palette, io: StringIO.new)
    display.iteration_started(
      iteration: 1, max_iterations: 10, phase: :gather, tools: gather_tools, tool_choice: 'required'
    )

    expect(palette[:iteration_header]).to have_received(:render).with(/Iteration/)
    expect(palette[:tool_name]).to have_received(:render).with('gather')
    expect(palette[:tool_name]).to have_received(:render).with('web_search')
    expect(palette[:tool_name]).to have_received(:render).with('alpha-vantage__time_series_daily')
  end
end

describe Cli::IterationDisplay, '#iteration_started flushing' do
  it 'flushes the IO so the user sees the announcement before the model responds' do
    flushable = FlushCountingIO.new
    display = Cli::IterationDisplay.new(Cli::Styles.palette, io: flushable)
    start_iteration(display)
    expect(flushable.flush_count).to be >= 1
  end
end

describe Cli::IterationDisplay, '#model_output search calls' do
  it 'renders web_search action and query' do
    display, io = build_display
    display.model_output(output_items: [
                           { 'type' => 'web_search_call',
                             'action' => { 'type' => 'search', 'query' => 'AAPL earnings beat' } }
                         ])
    expect(io.string).to include('web_search')
    expect(io.string).to include('AAPL earnings beat')
  end

  it 'omits the query line when no query is present' do
    display, io = build_display
    display.model_output(output_items: [{ 'type' => 'web_search_call', 'action' => {} }])
    expect(io.string).to include('web_search')
    expect(io.string).not_to include('query:')
  end

  it 'renders custom_tool_call name and pretty-printed input' do
    display, io = build_display
    item = {
      'type' => 'custom_tool_call', 'name' => 'x_keyword_search',
      'input' => '{"query":"PLTR squeeze","limit":"10"}'
    }
    display.model_output(output_items: [item])
    expect(io.string).to include('x_keyword_search')
    expect(io.string).to include('PLTR squeeze')
  end
end

describe Cli::IterationDisplay, '#model_output function calls' do
  it 'renders function_call requests so the user knows what the model wants' do
    display, io = build_display
    item = {
      'type' => 'function_call', 'name' => 'hellthread__fourChanCatalog',
      'arguments' => '{"board":"biz"}'
    }
    display.model_output(output_items: [item])
    expect(io.string).to include('hellthread__fourChanCatalog')
    expect(io.string).to include('biz')
  end
end

describe Cli::IterationDisplay, '#tool_call_started and #tool_call_completed' do
  it 'prints the tool call and its result progressively, in dispatch order' do
    display, io = build_display
    fc = {
      'type' => 'function_call', 'name' => 'alpha-vantage__time_series_daily',
      'arguments' => '{"symbol":"AAPL"}'
    }
    display.tool_call_started(function_call: fc)
    display.tool_call_completed(
      function_call: fc,
      result: { name: 'alpha-vantage__time_series_daily', call_id: 'av_1', result: '{"price":150}' }
    )

    expect(io.string).to include('Calling').and include('alpha-vantage__time_series_daily')
    expect(io.string).to include('AAPL').and include('result').and include('150')
  end
end

describe Cli::IterationDisplay, '#tool_call_completed truncation' do
  it 'truncates a long result with an ellipsis' do
    display, io = build_display
    long = 'x' * 1000

    display.tool_call_completed(
      function_call: { 'name' => 'hellthread__fourChanCatalog' },
      result: { name: 'hellthread__fourChanCatalog', call_id: 'h_1', result: long }
    )

    expect(io.string).to include('…')
    expect(io.string.length).to be < long.length + 200
  end
end

describe Cli::IterationDisplay, '#tool_call flushing' do
  it 'flushes after each call so throttled dispatches are visible immediately' do
    flushes = 0
    flushable = StringIO.new
    flushable.define_singleton_method(:flush) do
      flushes += 1
      super()
    end
    display = Cli::IterationDisplay.new(Cli::Styles.palette, io: flushable)
    fc = { 'type' => 'function_call', 'name' => 'alpha-vantage__time_series_daily', 'arguments' => '{}' }

    display.tool_call_started(function_call: fc)
    display.tool_call_completed(function_call: fc,
                                result: { name: 'av', call_id: 'av_1', result: 'ok' })

    expect(flushes).to be >= 2
  end
end

describe Cli::IterationDisplay, '#iteration_finished' do
  it 'emits a trailing blank line so iterations are visually separated' do
    display, io = build_display
    display.iteration_finished(iteration: 1)
    expect(io.string).to eq("\n")
  end
end
