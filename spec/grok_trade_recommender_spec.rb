require_relative "../spec/spec_helper"
require_relative "../scripts/grok_trade_recommender"

describe GrokTradeRecommender do
  describe "#initialize" do
    it "stores liquidity_amount" do
      recommender = described_class.new(5000)
      expect(recommender.instance_variable_get(:@liquidity_amount)).to eq(5000)
    end

    it "accepts string amount" do
      recommender = described_class.new("5000")
      expect(recommender.instance_variable_get(:@liquidity_amount)).to eq("5000")
    end
  end

  describe "#run" do
    let(:stock_trade) do
      Trading::GrokTradeService::Trade.new(
        type: "stock",
        symbol: "AAPL",
        min_price: 150.0,
        max_price: 160.0,
        confidence: 75,
        reasoning: "Strong fundamentals"
      )
    end

    let(:option_trade) do
      Trading::GrokTradeService::Trade.new(
        type: "option",
        symbol: "TSLA",
        min_price: 3.0,
        max_price: 7.0,
        confidence: 60,
        reasoning: "Bullish setup",
        strike_price: 250.0,
        expiration_date_min: "2026-05-15",
        expiration_date_max: "2026-05-22",
        option_type: "call",
        position_type: "buy"
      )
    end

    it "displays trades and exits with 0 on success" do
      recommender = described_class.new(5000)
      result = Trading::GrokTradeService::Result.new(
        trades: [stock_trade, option_trade],
        error_message: nil
      )

      allow_any_instance_of(Trading::GrokTradeService).to receive(:call).and_return(result)
      allow(recommender).to receive(:display_trades)

      expect { recommender.run }.to raise_error(SystemExit) { |e| expect(e.status).to eq(0) }
      expect(recommender).to have_received(:display_trades)
    end

    it "displays error and exits with 1 on failure" do
      recommender = described_class.new(5000)
      result = Trading::GrokTradeService::Result.new(
        trades: [],
        error_message: "API error"
      )

      allow_any_instance_of(Trading::GrokTradeService).to receive(:call).and_return(result)
      allow(recommender).to receive(:display_error)

      expect { recommender.run }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      expect(recommender).to have_received(:display_error).with("API error")
    end
  end

  describe "#display_trades" do
    let(:recommender) { described_class.new(5000) }

    let(:stock_trade) do
      Trading::GrokTradeService::Trade.new(
        type: "stock",
        symbol: "AAPL",
        min_price: 150.0,
        max_price: 160.0,
        confidence: 75,
        reasoning: "Strong fundamentals"
      )
    end

    let(:option_trade) do
      Trading::GrokTradeService::Trade.new(
        type: "option",
        symbol: "TSLA",
        min_price: 3.0,
        max_price: 7.0,
        confidence: 60,
        reasoning: "Bullish setup",
        strike_price: 250.0,
        expiration_date_min: "2026-05-15",
        expiration_date_max: "2026-05-22",
        option_type: "call",
        position_type: "buy"
      )
    end

    it "outputs header with recommendation count" do
      trades = [stock_trade, option_trade]

      expect { recommender.send(:display_trades, trades) }.to output(/Total Recommendations: 2/).to_stdout
    end

    it "displays stocks section when stocks are present" do
      trades = [stock_trade]

      expect { recommender.send(:display_trades, trades) }.to output(/STOCKS/).to_stdout
    end

    it "displays options section when options are present" do
      trades = [option_trade]

      expect { recommender.send(:display_trades, trades) }.to output(/OPTIONS/).to_stdout
    end

    it "displays both sections when both types are present" do
      trades = [stock_trade, option_trade]
      output = capture_stdout { recommender.send(:display_trades, trades) }

      expect(output).to include("STOCKS")
      expect(output).to include("OPTIONS")
    end

    it "handles empty trades array" do
      trades = []

      expect { recommender.send(:display_trades, trades) }.to output(/Total Recommendations: 0/).to_stdout
    end
  end

  describe "#display_stock_card" do
    let(:recommender) { described_class.new(5000) }
    let(:stock_trade) do
      Trading::GrokTradeService::Trade.new(
        type: "stock",
        symbol: "AAPL",
        min_price: 150.0,
        max_price: 160.0,
        confidence: 75,
        reasoning: "Strong fundamentals"
      )
    end

    it "displays stock symbol" do
      expect { recommender.send(:display_stock_card, stock_trade, 1) }.to output(/AAPL/).to_stdout
    end

    it "displays price range" do
      output = capture_stdout { recommender.send(:display_stock_card, stock_trade, 1) }
      expect(output).to include("$150")
      expect(output).to include("$160")
    end

    it "displays confidence" do
      expect { recommender.send(:display_stock_card, stock_trade, 1) }.to output(/75%/).to_stdout
    end

    it "displays reasoning" do
      expect { recommender.send(:display_stock_card, stock_trade, 1) }.to output(/Strong fundamentals/).to_stdout
    end

    it "displays correct card number" do
      expect { recommender.send(:display_stock_card, stock_trade, 3) }.to output(/3\./).to_stdout
    end
  end

  describe "#display_option_card" do
    let(:recommender) { described_class.new(5000) }
    let(:option_trade) do
      Trading::GrokTradeService::Trade.new(
        type: "option",
        symbol: "TSLA",
        min_price: 3.0,
        max_price: 7.0,
        confidence: 60,
        reasoning: "Bullish setup",
        strike_price: 250.0,
        expiration_date_min: "2026-05-15",
        expiration_date_max: "2026-05-22",
        option_type: "call",
        position_type: "buy"
      )
    end

    it "displays option symbol and type" do
      output = capture_stdout { recommender.send(:display_option_card, option_trade, 1) }
      expect(output).to include("TSLA")
      expect(output).to include("CALL")
      expect(output).to include("BUY")
    end

    it "displays strike price" do
      expect { recommender.send(:display_option_card, option_trade, 1) }.to output(/\$250/).to_stdout
    end

    it "displays expiration range" do
      output = capture_stdout { recommender.send(:display_option_card, option_trade, 1) }
      expect(output).to include("2026-05-15")
      expect(output).to include("2026-05-22")
    end

    it "displays premium range" do
      output = capture_stdout { recommender.send(:display_option_card, option_trade, 1) }
      expect(output).to include("$3")
      expect(output).to include("$7")
    end

    it "displays confidence" do
      expect { recommender.send(:display_option_card, option_trade, 1) }.to output(/60%/).to_stdout
    end

    it "displays reasoning" do
      expect { recommender.send(:display_option_card, option_trade, 1) }.to output(/Bullish setup/).to_stdout
    end

    it "handles missing optional fields" do
      trade_no_expiry = Trading::GrokTradeService::Trade.new(
        type: "option",
        symbol: "SPY",
        min_price: 5.0,
        max_price: 10.0,
        confidence: 50,
        reasoning: "Test",
        option_type: "put",
        position_type: "sell"
      )

      expect { recommender.send(:display_option_card, trade_no_expiry, 1) }.to output(/N\/A/).to_stdout
    end
  end

  describe "#format_price" do
    let(:recommender) { described_class.new(5000) }

    it "formats price above 1 with 2 decimal places" do
      result = recommender.send(:format_price, 150.25)
      expect(result).to eq("$150.25")
    end

    it "formats whole dollar amounts" do
      result = recommender.send(:format_price, 150)
      expect(result).to eq("$150")
    end

    it "formats price below 1 with 4 decimal places" do
      result = recommender.send(:format_price, 0.0123)
      expect(result).to eq("$0.0123")
    end

    it "formats very small prices" do
      result = recommender.send(:format_price, 0.001)
      expect(result).to eq("$0.001")
    end

    it "handles nil price" do
      result = recommender.send(:format_price, nil)
      expect(result).to eq("N/A")
    end

    it "formats zero as N/A" do
      result = recommender.send(:format_price, 0)
      expect(result).to eq("$0")
    end
  end

  describe "#confidence_indicator" do
    let(:recommender) { described_class.new(5000) }

    it "returns 10 filled bars for 100% confidence" do
      result = recommender.send(:confidence_indicator, 100)
      expect(result).to include("█" * 10)
    end

    it "returns 5 filled bars for 50% confidence" do
      result = recommender.send(:confidence_indicator, 50)
      expect(result).to include("█" * 5)
      expect(result).to include("░" * 5)
    end

    it "returns 1 filled bar for 10% confidence" do
      result = recommender.send(:confidence_indicator, 10)
      expect(result).to include("█")
    end

    it "returns no filled bars for 0% confidence" do
      result = recommender.send(:confidence_indicator, 0)
      expect(result).not_to include("█")
      expect(result).to include("░" * 10)
    end

    it "returns 7 filled bars for 75% confidence" do
      result = recommender.send(:confidence_indicator, 75)
      expect(result).to include("█" * 7)
      expect(result).to include("░" * 3)
    end
  end

  describe "#display_error" do
    let(:recommender) { described_class.new(5000) }

    it "displays error header" do
      expect { recommender.send(:display_error, "Test error") }.to output(/Error/).to_stdout
    end

    it "displays error message" do
      expect { recommender.send(:display_error, "Test error message") }.to output(/Test error message/).to_stdout
    end

    it "handles long error messages" do
      long_message = "This is a very long error message that should be displayed properly"
      expect { recommender.send(:display_error, long_message) }.to output(/This is a very long error message/).to_stdout
    end
  end
end

# Helper to capture stdout
def capture_stdout
  old_stdout = $stdout
  $stdout = StringIO.new
  yield
  $stdout.string
ensure
  $stdout = old_stdout
end
