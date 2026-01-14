class PriceTicker {
  final String symbol;
  final double price; // Last Price
  final double priceChangePercent;
  final double highPrice;
  final double lowPrice;
  final double volume; // Base Asset Volume
  final double quoteVolume; // Quote Asset Volume

  // Extended Fields
  final double bidPrice;
  final double askPrice;
  final double weightedAvgPrice;
  final int count; // Trade Count
  final double openPrice;

  PriceTicker({
    required this.symbol,
    required this.price,
    this.priceChangePercent = 0.0,
    this.highPrice = 0.0,
    this.lowPrice = 0.0,
    this.volume = 0.0,
    this.quoteVolume = 0.0,
    this.bidPrice = 0.0,
    this.askPrice = 0.0,
    this.weightedAvgPrice = 0.0,
    this.count = 0,
    this.openPrice = 0.0,
  });

  factory PriceTicker.fromJson(Map<String, dynamic> json) {
    return PriceTicker(
      symbol: json['symbol'] ?? 'Unknown',
      price: double.tryParse(json['lastPrice'].toString()) ?? 0.0,
      priceChangePercent:
          double.tryParse(json['priceChangePercent'].toString()) ?? 0.0,
      highPrice: double.tryParse(json['highPrice'].toString()) ?? 0.0,
      lowPrice: double.tryParse(json['lowPrice'].toString()) ?? 0.0,
      volume: double.tryParse(json['volume'].toString()) ?? 0.0,
      quoteVolume: double.tryParse(json['quoteVolume'].toString()) ?? 0.0,
      bidPrice: double.tryParse(json['bidPrice'].toString()) ?? 0.0,
      askPrice: double.tryParse(json['askPrice'].toString()) ?? 0.0,
      weightedAvgPrice:
          double.tryParse(json['weightedAvgPrice'].toString()) ?? 0.0,
      count: int.tryParse(json['count'].toString()) ?? 0,
      openPrice: double.tryParse(json['openPrice'].toString()) ?? 0.0,
    );
  }

  factory PriceTicker.fromStreamJson(Map<String, dynamic> json) {
    final price = double.tryParse(json['c'].toString()) ?? 0.0;
    final openPrice = double.tryParse(json['o'].toString()) ?? 0.0;
    final percentChange = openPrice != 0
        ? ((price - openPrice) / openPrice) * 100
        : 0.0;

    return PriceTicker(
      symbol: json['s'] ?? 'Unknown',
      price: price,
      priceChangePercent: percentChange,
      highPrice: double.tryParse(json['h'].toString()) ?? 0.0,
      lowPrice: double.tryParse(json['l'].toString()) ?? 0.0,
      volume: double.tryParse(json['v'].toString()) ?? 0.0,
      quoteVolume: double.tryParse(json['q'].toString()) ?? 0.0,
      // MiniTicker doesn't have Bid/Ask/Count, set to 0 or defaults
      bidPrice: 0.0,
      askPrice: 0.0,
      weightedAvgPrice: 0.0,
      count: 0,
      openPrice: openPrice,
    );
  }
}

class Candle {
  final int openTime;
  final double open;
  final double high;
  final double low;
  final double close;

  Candle({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory Candle.fromJson(List<dynamic> data) {
    return Candle(
      openTime: data[0] as int,
      open: double.parse(data[1] as String),
      high: double.parse(data[2] as String),
      low: double.parse(data[3] as String),
      close: double.parse(data[4] as String),
    );
  }
}
