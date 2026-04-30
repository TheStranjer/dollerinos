require_relative "../spec/spec_helper"
require_relative "../scripts/grok_trade_recommender"
require "tempfile"
require "json"

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

    it "stores positions_file when provided" do
      recommender = described_class.new(5000, positions_file: "positions.json")
      expect(recommender.instance_variable_get(:@positions_file)).to eq("positions.json")
    end

    it "stores nil positions_file by default" do
      recommender = described_class.new(5000)
      expect(recommender.instance_variable_get(:@positions_file)).to be_nil
    end
  end

  describe "#load_positions" do
    it "loads positions from valid JSON file" do
      positions_json = [
        {
          "type" => "stock",
          "symbol" => "AAPL",
          "quantity" => 100,
          "position_type" => "long"
        },
        {
          "type" => "option",
          "symbol" => "TSLA",
          "quantity" => 5,
          "position_type" => "long",
          "strike_price" => 250.0,
          "expiration_date" => "2026-05-15",
          "option_type" => "call"
        }
      ]

      temp_file = Tempfile.new("positions.json")
      temp_file.write(JSON.generate(positions_json))
      temp_file.close

      recommender = described_class.new(5000, positions_file: temp_file.path)
      positions = recommender.send(:load_positions)

      expect(positions).to be_an(Array)
      expect(positions.length).to eq(2)
      expect(positions[0].symbol).to eq("AAPL")
      expect(positions[1].symbol).to eq("TSLA")

      temp_file.unlink
    end

    it "raises error when positions file does not exist" do
      recommender = described_class.new(5000, positions_file: "/nonexistent/path.json")
      expect { recommender.send(:load_positions) }.to raise_error(/Positions file not found/)
    end

    it "raises error for invalid JSON" do
      temp_file = Tempfile.new("positions.json")
      temp_file.write("{ invalid json }")
      temp_file.close

      recommender = described_class.new(5000, positions_file: temp_file.path)
      expect { recommender.send(:load_positions) }.to raise_error(/Invalid JSON/)

      temp_file.unlink
    end

    it "raises error when JSON is not an array" do
      temp_file = Tempfile.new("positions.json")
      temp_file.write(JSON.generate({ "positions" => [] }))
      temp_file.close

      recommender = described_class.new(5000, positions_file: temp_file.path)
      expect { recommender.send(:load_positions) }.to raise_error(/must contain a JSON array/)

      temp_file.unlink
    end
  end

  describe "#build_position" do
    let(:recommender) { described_class.new(5000) }

    it "builds stock position from hash" do
      data = {
        "type" => "stock",
        "symbol" => "aapl",
        "quantity" => 100,
        "position_type" => "long"
      }

      position = recommender.send(:build_position, data)

      expect(position.type).to eq("stock")
      expect(position.symbol).to eq("AAPL")
      expect(position.quantity).to eq(100)
      expect(position.position_type).to eq("long")
    end

    it "builds option position from hash" do
      data = {
        "type" => "option",
        "symbol" => "tsla",
        "quantity" => 5,
        "position_type" => "long",
        "strike_price" => 250.0,
        "expiration_date" => "2026-05-15",
        "option_type" => "call"
      }

      position = recommender.send(:build_position, data)

      expect(position.type).to eq("option")
      expect(position.symbol).to eq("TSLA")
      expect(position.quantity).to eq(5)
      expect(position.position_type).to eq("long")
      expect(position.strike_price).to eq(250.0)
      expect(position.expiration_date).to eq("2026-05-15")
      expect(position.option_type).to eq("call")
    end

    it "handles short positions" do
      data = {
        "type" => "stock",
        "symbol" => "spy",
        "quantity" => 50,
        "position_type" => "SHORT"
      }

      position = recommender.send(:build_position, data)

      expect(position.position_type).to eq("short")
    end

    it "normalizes symbol to uppercase" do
      data = {
        "type" => "stock",
        "symbol" => "  aapl  ",
        "quantity" => 100,
        "position_type" => "long"
      }

      position = recommender.send(:build_position, data)

      expect(position.symbol).to eq("AAPL")
    end

    it "normalizes type to lowercase" do
      data = {
        "type" => "STOCK",
        "symbol" => "AAPL",
        "quantity" => 100,
        "position_type" => "long"
      }

      position = recommender.send(:build_position, data)

      expect(position.type).to eq("stock")
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

    it "loads positions from file when positions_file is provided" do
      positions_json = [
        {
          "type" => "stock",
          "symbol" => "AAPL",
          "quantity" => 100,
          "position_type" => "long"
        }
      ]

      temp_file = Tempfile.new("positions.json")
      temp_file.write(JSON.generate(positions_json))
      temp_file.close

      recommender = described_class.new(5000, positions_file: temp_file.path)
      result = Trading::GrokTradeService::Result.new(
        trades: [stock_trade],
        error_message: nil
      )

      allow_any_instance_of(Trading::GrokTradeService).to receive(:call).and_return(result)
      allow(recommender).to receive(:display_trades)

      expect_any_instance_of(Trading::GrokTradeService).to receive(:initialize)
        .with(hash_including(positions: anything))
        .and_call_original

      expect { recommender.run }.to raise_error(SystemExit) { |e| expect(e.status).to eq(0) }

      temp_file.unlink
    end

    it "passes empty positions when no positions file" do
      recommender = described_class.new(5000)
      result = Trading::GrokTradeService::Result.new(
        trades: [stock_trade],
        error_message: nil
      )

      allow_any_instance_of(Trading::GrokTradeService).to receive(:call).and_return(result)
      allow(recommender).to receive(:display_trades)

      expect_any_instance_of(Trading::GrokTradeService).to receive(:initialize)
        .with(hash_including(positions: []))
        .and_call_original

      expect { recommender.run }.to raise_error(SystemExit) { |e| expect(e.status).to eq(0) }
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
