# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

module UserPromptHelpers
  def first_call_input(service)
    xai = FakeXaiClient.new([{ 'output' => [trade_call(trades: [valid_trade])] }])
    service.instance_variable_set(:@config, service.instance_variable_get(:@config).dup.tap do |cfg|
      cfg.xai_client_factory = xai.factory
    end)
    service.call
    xai.calls.first[:input]
  end

  def user_messages(service)
    first_call_input(service).select { |entry| entry[:role] == 'user' }
  end
end

RSpec.configure { |c| c.include UserPromptHelpers }

describe Trading::GrokTradeService, 'standard user prompt' do
  let(:position) { described_class::Position.new(type: 'stock', symbol: 'AAPL', quantity: 100, position_type: 'long') }

  it 'includes the liquidity amount and core sections' do
    content = user_messages(build_service(liquidity_amount: 12_345)).last[:content]
    expect(content).to include('12345').and include('confidence').and include('reasoning')
  end

  it 'includes a positions section when positions are provided' do
    content = user_messages(build_service(positions: [position])).last[:content]
    expect(content).to include('100 shares of AAPL').and include('current positions')
  end
end

describe Trading::GrokTradeService, 'custom user_prompt option' do
  it 'omits a custom user message when no user_prompt is supplied' do
    expect(user_messages(build_service).size).to eq(1)
  end

  it 'prepends a user_prompt as its own user message at the outset' do
    messages = user_messages(build_service(user_prompt: 'Focus on tech stocks'))
    expect(messages.size).to eq(2)
    expect(messages.first[:content]).to eq('Focus on tech stocks')
  end

  it 'ignores blank user_prompt values' do
    expect(user_messages(build_service(user_prompt: '   ')).size).to eq(1)
  end

  it 'strips whitespace from a non-blank user_prompt' do
    messages = user_messages(build_service(user_prompt: "  Hello world\n"))
    expect(messages.first[:content]).to eq('Hello world')
  end
end

describe Trading::GrokTradeService, 'user_prompt ordering' do
  it 'places the custom user_prompt before the standard liquidity prompt' do
    input = first_call_input(build_service(user_prompt: 'Focus on tech stocks'))
    expect(input.first[:role]).to eq('system')
    expect(input[1]).to eq(role: 'user', content: 'Focus on tech stocks')
    expect(input[2][:role]).to eq('user')
    expect(input[2][:content]).to include('available for trading')
  end
end
