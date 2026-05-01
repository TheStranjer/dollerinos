# frozen_string_literal: true

require_relative '../../lib/grok_trade_service'

describe Trading::GrokTradeService, 'validation' do
  it 'fails when liquidity_amount is not positive' do
    result = build_service(liquidity_amount: 0).call
    expect(result.error_message).to include('positive number')
  end

  it 'fails when XAI key is missing' do
    expect(build_service(xai_api_key: nil).call.error_message).to include('XAI_API_KEY')
  end

  it 'fails when HELLTHREAD key is missing' do
    expect(build_service(hellthread_api_key: nil).call.error_message).to include('HELLTHREAD_API_KEY')
  end

  it 'fails when UNUSUAL_WHALES key is missing' do
    expect(build_service(unusual_whales_api_key: nil).call.error_message).to include('UNUSUAL_WHALES_API_KEY')
  end

  it 'fails when max_iterations is below 1' do
    expect(build_service(max_iterations: 0).call.error_message).to include('max_iterations')
  end
end
