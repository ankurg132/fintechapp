import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'price_model.dart';

class PriceService {
  final String _wsBaseUrl = 'wss://stream.binance.com:9443/ws';
  final String _restBaseUrl = 'https://api.binance.com/api/v3';

  // Fetch 24hr ticker for a specific symbol
  Future<PriceTicker> fetchTicker24h(String symbol) async {
    final response = await http.get(
      Uri.parse('$_restBaseUrl/ticker/24hr?symbol=${symbol.toUpperCase()}'),
    );

    if (response.statusCode == 200) {
      return PriceTicker.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load ticker for $symbol');
    }
  }

  // Fetch candles
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
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Candle.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load candles for $symbol');
    }
  }

  // Helper to fetch the open price from the START of the period (N intervals ago)
  // Used to calculate accurate 1H, 1D, 1W, 1M change
  Future<double> fetchOpenPriceForPeriod(String symbol, String filter) async {
    // Strategy: For each filter, we fetch enough candles to span that period,
    // then use the FIRST candle's open price as our "starting point"

    String interval;
    int limit;

    switch (filter) {
      case '1H':
        // 1 hour ago: fetch 2 x 1h candles, use first open
        interval = '1h';
        limit = 2;
        break;
      case '1D':
        // 24 hours ago: fetch 25 x 1h candles, use first open
        interval = '1h';
        limit = 25;
        break;
      case '1W':
        // 7 days ago: fetch 8 x 1d candles, use first open
        interval = '1d';
        limit = 8;
        break;
      case '1M':
        // 30 days ago: fetch 31 x 1d candles, use first open
        interval = '1d';
        limit = 31;
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
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        // Use the FIRST candle's open price (oldest in the range)
        final candle = Candle.fromJson(data[0]);
        return candle.open;
      }
    }
    return 0.0;
  }

  // Stream for a specific symbol
  Stream<PriceTicker> getTickerStream(String symbol) {
    // Using miniTicker for efficiency in lists
    final channel = WebSocketChannel.connect(
      Uri.parse('$_wsBaseUrl/${symbol.toLowerCase()}@miniTicker'),
    );
    return channel.stream.map((event) {
      final json = jsonDecode(event);
      return PriceTicker.fromStreamJson(json);
    });
  }
}
