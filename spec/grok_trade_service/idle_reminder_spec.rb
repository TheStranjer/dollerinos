# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'idle reminder' do
  it 'prods Grok with a user reminder when it returns no function calls' do
    idle_response = {
      'output' => [
        { 'type' => 'message', 'role' => 'assistant', 'content' => [{ 'type' => 'text', 'text' => 'Thinking...' }] }
      ]
    }
    finishing_response = { 'output' => [trade_call(trades: [valid_trade])] }
    xai = FakeXaiClient.new([idle_response, finishing_response])

    build_service(xai_client: xai, max_iterations: 4).call

    second_input = xai.calls[1][:input]
    reminder_present = second_input.any? do |item|
      (item[:role] || item['role']) == 'user' &&
        (item[:content] || item['content']).to_s.include?(described_class::FUNCTION_NAME)
    end
    expect(reminder_present).to be(true)
  end
end
