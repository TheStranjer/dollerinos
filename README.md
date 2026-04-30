# Dollerinos - AI-Powered Trading Recommendations

Dollerinos is a Ruby application that generates AI-powered stock and options trading recommendations using Grok-4.20-reasoning from xAI. It integrates with multiple data sources to provide informed trading insights based on current market conditions, unusual activity, and emerging opportunities.

## Features

- **AI-Powered Analysis**: Uses xAI's Grok-4.20-reasoning model for financial analysis
- **Multi-Source Research**: Integrates with:
  - X Search for real-time market data
  - Web Search for broader market intelligence
  - Hellthread MCP (Discourse, 4chan, RSS reader tools)
  - Unusual Whales MCP (options flow and market data)
- **Stock & Options Recommendations**: Returns both equity and derivatives trading ideas
- **Confidence Scoring**: Each recommendation includes a 0-100 confidence level
- **Terminal UI**: Color-coded, formatted output for easy reading
- **Input Validation**: Validates all inputs and API responses

## Requirements

- Ruby 4.0.0 or later
- Bundler 2.6.0 or later

## API Keys

The following API keys are required and must be set as environment variables:

```bash
export XAI_API_KEY=your_xai_api_key
export HELLTHREAD_API_KEY=your_hellthread_api_key
export UNUSUAL_WHALES_API_KEY=your_unusual_whales_api_key
```

## Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd dollerinos
```

2. Install dependencies:
```bash
bundle install
```

3. Configure environment variables:
```bash
export XAI_API_KEY=your_xai_api_key
export HELLTHREAD_API_KEY=your_hellthread_api_key
export UNUSUAL_WHALES_API_KEY=your_unusual_whales_api_key
```

## Usage

Run the trade recommender with your available liquidity amount:

```bash
./scripts/grok_trade_recommender.rb <amount>
```

### Examples

```bash
# Get recommendations for a $10,000 account
./scripts/grok_trade_recommender.rb 10000

# Get recommendations for a $50,000 account
./scripts/grok_trade_recommender.rb 50000

# Get recommendations for a $1,500 account
./scripts/grok_trade_recommender.rb 1500
```

### Sample Output

The tool displays recommendations organized by type:

```
🚀 Grok Trade Recommendations

Total Recommendations: 5
================================================================================

📈 STOCKS (3)

  1. AAPL
     Price Range: $150.00 - $160.00
     Confidence: ██████████ (100%)
     Thesis: Strong technical setup with positive earnings catalyst expected next quarter

  2. TSLA
     Price Range: $200.00 - $220.00
     Confidence: ████████░░ (80%)
     Thesis: Undervalued based on EV market trends and Q2 deliveries expectations

📊 OPTIONS (2)

  1. SPY CALL - BUY
     Strike:      $450.00
     Expiration:  2024-05-17 - 2024-05-24
     Premium:     $2.50 - $3.50
     Confidence: ███████░░░ (70%)
     Thesis: Bullish technical setup on major support level
```

## Architecture

### GrokTradeService

The core service class that handles:
- Input validation
- API communication with xAI
- Trade extraction from API responses
- Error handling and result formatting

**Key Components:**
- `Trade`: Struct representing a single trade recommendation with validation
- `Result`: Struct for service responses (success/failure with trades or error message)

### GrokTradeRecommender

CLI script that:
- Parses command-line arguments
- Instantiates `GrokTradeService`
- Formats and displays results with styled output
- Handles error reporting

## Testing

Run the test suite with:

```bash
bundle exec rspec
```

Run specific test file:
```bash
bundle exec rspec spec/grok_trade_service_spec.rb
```

Run with verbose output:
```bash
bundle exec rspec -f documentation
```

## Development

### Project Structure

```
dollerinos/
├── lib/
│   └── grok_trade_service.rb       # Core service class
├── scripts/
│   └── grok_trade_recommender.rb   # CLI entry point
├── spec/
│   ├── grok_trade_service_spec.rb
│   ├── grok_trade_recommender_spec.rb
│   └── spec_helper.rb
├── Gemfile                          # Ruby dependencies
└── README.md
```

### Dependencies

- **activesupport**: For string and object extensions
- **charm**: Terminal styling and UI components
- **faraday**: HTTP client (for potential future use)
- **rspec**: Testing framework

## Trade Recommendation Structure

Each trade recommendation includes:

### For Stocks
- `type`: "stock"
- `symbol`: Stock ticker (e.g., "AAPL")
- `min_price`: Minimum price target
- `max_price`: Maximum price target
- `confidence`: 0-100 confidence level
- `reasoning`: Explanation for the recommendation

### For Options
- `type`: "option"
- `symbol`: Underlying stock ticker
- `strike_price`: Option strike price
- `expiration_date_min`: Earliest expiration date
- `expiration_date_max`: Latest expiration date
- `option_type`: "call" or "put"
- `position_type`: "buy" or "sell"
- `min_price`: Minimum premium estimate
- `max_price`: Maximum premium estimate
- `confidence`: 0-100 confidence level
- `reasoning`: Explanation for the recommendation

## Error Handling

The tool handles various error scenarios:
- Invalid liquidity amounts (must be positive numbers)
- Missing API keys
- API failures
- Invalid JSON responses
- No valid recommendations returned

All errors are displayed in a red error message format.

## System Prompt

The AI system uses the following prompt to generate recommendations:

> You are a financial analysis assistant specializing in identifying promising trading opportunities. Use available search tools to research current market conditions, sector trends, unusual activity, and emerging opportunities. After completing all external tool calls, you must finish by calling trade_recommendations with an array of actionable trade ideas suitable for the given liquidity amount.

## Limitations & Disclaimers

- Recommendations are AI-generated and should not be considered financial advice
- Always conduct your own due diligence before trading
- This tool is for research and educational purposes
- Market conditions change rapidly; recommendations may become outdated
- Options trading carries significant risk; understand the risks before trading

## Contributing

Feel free to submit issues and enhancement requests!

## License

MIT License (or specify your preferred license)

## Troubleshooting

### "XAI_API_KEY is not configured"
Make sure the environment variable is set:
```bash
export XAI_API_KEY=your_key_here
```

### xAI request failed
Check:
- Your API key is valid
- You have sufficient API credits
- The xAI API endpoint is accessible
- Your network connection is working

### "xAI returned no valid trade recommendations"
The API may not have returned recommendations for your liquidity amount or market conditions. Try again or adjust your account size.

### Tests fail
Ensure all dependencies are installed:
```bash
bundle install --redownload
```
