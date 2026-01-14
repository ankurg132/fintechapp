import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'price_model.dart';

// ============================================================================
// ISOLATE PARSING FUNCTIONS (Top-level functions required for compute())
// ============================================================================

/// Parse ticker JSON in isolate
PriceTicker _parseTicker(String body) {
  return PriceTicker.fromJson(jsonDecode(body));
}

/// Parse candles list in isolate
List<Candle> _parseCandles(String body) {
  final List<dynamic> data = jsonDecode(body);
  return data.map((e) => Candle.fromJson(e)).toList();
}

/// Parse order book in isolate
OrderBook _parseOrderBook(String body) {
  return OrderBook.fromJson(jsonDecode(body));
}

/// Parse trades list in isolate
List<Trade> _parseTrades(String body) {
  final List<dynamic> data = jsonDecode(body);
  return data.map((e) => Trade.fromJson(e)).toList();
}

/// Parse book ticker in isolate
BookTicker _parseBookTicker(String body) {
  return BookTicker.fromJson(jsonDecode(body));
}

/// Parse avg price in isolate
AvgPrice _parseAvgPrice(String body) {
  return AvgPrice.fromJson(jsonDecode(body));
}

/// Parse first candle's open price in isolate
double _parseFirstOpenPrice(String body) {
  final List<dynamic> data = jsonDecode(body);
  if (data.isNotEmpty) {
    final candle = Candle.fromJson(data[0]);
    return candle.open;
  }
  return 0.0;
}

// ============================================================================
// PRICE SERVICE
// ============================================================================

class PriceService {
  final String _wsBaseUrl = 'wss://stream.binance.com:9443/ws';
  final String _restBaseUrl = 'https://api.binance.com/api/v3';

  // Fetch 24hr ticker for a specific symbol (parsed in isolate)
  Future<PriceTicker> fetchTicker24h(String symbol) async {
    final response = await http.get(
      Uri.parse('$_restBaseUrl/ticker/24hr?symbol=${symbol.toUpperCase()}'),
    );

    if (response.statusCode == 200) {
      return compute(_parseTicker, response.body);
    } else {
      throw Exception('Failed to load ticker for $symbol');
    }
  }

  // Fetch candles (parsed in isolate)
  Future<List<Candle>> fetchCandles(
    String symbol, {
    String interval = '1h',
    int limit = 24,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$_restBaseUrl/klines?symbol=${symbol.toUpperCase()}&interval=$interval&limit=$limit',
      ),
    );

    if (response.statusCode == 200) {
      return compute(_parseCandles, response.body);
    } else {
      throw Exception('Failed to load candles for $symbol');
    }
  }

  // Fetch open price for period (parsed in isolate)
  Future<double> fetchOpenPriceForPeriod(String symbol, String filter) async {
    String interval;
    int limit;

    switch (filter) {
      case '1H':
        interval = '1h';
        limit = 2;
        break;
      case '1D':
        interval = '1h';
        limit = 25;
        break;
      case '1W':
        interval = '1d';
        limit = 8;
        break;
      case '1M':
        interval = '1d';
        limit = 31;
        break;
      case '1Y':
        interval = '1w';
        limit = 53;
        break;
      default:
        interval = '1d';
        limit = 2;
    }

    final response = await http.get(
      Uri.parse(
        '$_restBaseUrl/klines?symbol=${symbol.toUpperCase()}&interval=$interval&limit=$limit',
      ),
    );

    if (response.statusCode == 200) {
      return compute(_parseFirstOpenPrice, response.body);
    }
    return 0.0;
  }

  // Stream for a specific symbol with 500ms throttle to reduce UI rebuilds
  Stream<PriceTicker> getTickerStream(String symbol) {
    final channel = WebSocketChannel.connect(
      Uri.parse('$_wsBaseUrl/${symbol.toLowerCase()}@miniTicker'),
    );

    // Parse and throttle using RxDart
    return channel.stream
        .map((event) {
          final json = jsonDecode(event);
          return PriceTicker.fromStreamJson(json);
        })
        .throttleTime(const Duration(milliseconds: 500));
  }

  // Fetch Order Book (parsed in isolate)
  Future<OrderBook> fetchOrderBook(String symbol, {int limit = 10}) async {
    final response = await http.get(
      Uri.parse(
        '$_restBaseUrl/depth?symbol=${symbol.toUpperCase()}&limit=$limit',
      ),
    );

    if (response.statusCode == 200) {
      return compute(_parseOrderBook, response.body);
    } else {
      throw Exception('Failed to load order book for $symbol');
    }
  }

  // Fetch Recent Trades (parsed in isolate)
  Future<List<Trade>> fetchRecentTrades(String symbol, {int limit = 20}) async {
    final response = await http.get(
      Uri.parse(
        '$_restBaseUrl/trades?symbol=${symbol.toUpperCase()}&limit=$limit',
      ),
    );

    if (response.statusCode == 200) {
      return compute(_parseTrades, response.body);
    } else {
      throw Exception('Failed to load trades for $symbol');
    }
  }

  // Fetch Book Ticker (parsed in isolate)
  Future<BookTicker> fetchBookTicker(String symbol) async {
    final response = await http.get(
      Uri.parse(
        '$_restBaseUrl/ticker/bookTicker?symbol=${symbol.toUpperCase()}',
      ),
    );

    if (response.statusCode == 200) {
      return compute(_parseBookTicker, response.body);
    } else {
      throw Exception('Failed to load book ticker for $symbol');
    }
  }

  // Fetch Average Price (parsed in isolate)
  Future<AvgPrice> fetchAvgPrice(String symbol) async {
    final response = await http.get(
      Uri.parse('$_restBaseUrl/avgPrice?symbol=${symbol.toUpperCase()}'),
    );

    if (response.statusCode == 200) {
      return compute(_parseAvgPrice, response.body);
    } else {
      throw Exception('Failed to load avg price for $symbol');
    }
  }
}
