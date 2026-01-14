# Crypto Market Tracker

A real-time cryptocurrency tracking application built with Flutter, powered by the Binance API.

## Features

### Real-time Data
- **Live Price Updates**: WebSocket connection provides instant price updates
- **Multiple Cryptocurrencies**: Track BTC, ETH, SOL, BNB, ADA, XRP, LTC

### Homepage
- **Time Range Filters**: Toggle between 1H, 1D, 1W, 1M views
- **Dynamic Percentage**: Shows accurate price change for selected time range
- **Clean UI**: Modern card-based layout with live updates

### Detail Screen
- **Interactive Charts**: Line charts with gradient fills using fl_chart
- **Chart Time Ranges**: 1D, 1W, 1M, 1Y toggles
- **Market Stats**:
  - 24h High/Low
  - Volume (Base & Quote)
  - Range High/Low (based on chart selection)
  - 1H Change indicator
- **Extended Stats**:
  - Best Bid/Ask prices
  - Spread
  - Average Price (5-minute)
- **Order Book**: Live bids (green) and asks (red) with prices and quantities
- **Recent Trades**: Last trades with buy/sell indicators

## Tech Stack

- **Flutter** (Dart)
- **Binance API** (REST + WebSocket)
- **fl_chart** for charting
- **http** for REST requests
- **web_socket_channel** for real-time data

## Setup

```bash
flutter pub get
flutter run
```

## API Endpoints Used

| Endpoint | Purpose |
|----------|---------|
| `GET /api/v3/ticker/24hr` | 24h ticker stats |
| `GET /api/v3/klines` | Historical candlestick data |
| `WSS btcusdt@miniTicker` | Real-time price stream |

## Project Structure

```
lib/
├── main.dart              # App entry point
├── price_screen.dart      # Homepage with coin list
├── coin_card.dart         # Individual coin card widget
├── coin_detail_screen.dart # Detailed view with charts
├── price_model.dart       # Data models (PriceTicker, Candle)
└── price_service.dart     # API service layer
```

## License

MIT
