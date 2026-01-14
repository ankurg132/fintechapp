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

  /// Calculate percentage change from open to close
  double get changePercent => open != 0 ? ((close - open) / open) * 100 : 0.0;
}

/// Order Book Entry (bid or ask)
class OrderBookEntry {
  final double price;
  final double quantity;

  OrderBookEntry({required this.price, required this.quantity});

  factory OrderBookEntry.fromList(List<dynamic> data) {
    return OrderBookEntry(
      price: double.parse(data[0] as String),
      quantity: double.parse(data[1] as String),
    );
  }
}

/// Order Book with bids and asks
class OrderBook {
  final List<OrderBookEntry> bids;
  final List<OrderBookEntry> asks;

  OrderBook({required this.bids, required this.asks});

  factory OrderBook.fromJson(Map<String, dynamic> json) {
    return OrderBook(
      bids: (json['bids'] as List)
          .map((e) => OrderBookEntry.fromList(e))
          .toList(),
      asks: (json['asks'] as List)
          .map((e) => OrderBookEntry.fromList(e))
          .toList(),
    );
  }

  double get spread => asks.isNotEmpty && bids.isNotEmpty
      ? asks.first.price - bids.first.price
      : 0.0;
  double get spreadPercent => bids.isNotEmpty && bids.first.price > 0
      ? (spread / bids.first.price) * 100
      : 0.0;
}

/// Recent Trade
class Trade {
  final int id;
  final double price;
  final double qty;
  final int time;
  final bool isBuyerMaker;

  Trade({
    required this.id,
    required this.price,
    required this.qty,
    required this.time,
    required this.isBuyerMaker,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'] as int,
      price: double.parse(json['price'] as String),
      qty: double.parse(json['qty'] as String),
      time: json['time'] as int,
      isBuyerMaker: json['isBuyerMaker'] as bool,
    );
  }

  bool get isBuy => !isBuyerMaker; // If maker is seller, taker is buyer
}

/// Book Ticker (best bid/ask)
class BookTicker {
  final String symbol;
  final double bidPrice;
  final double bidQty;
  final double askPrice;
  final double askQty;

  BookTicker({
    required this.symbol,
    required this.bidPrice,
    required this.bidQty,
    required this.askPrice,
    required this.askQty,
  });

  factory BookTicker.fromJson(Map<String, dynamic> json) {
    return BookTicker(
      symbol: json['symbol'] as String,
      bidPrice: double.parse(json['bidPrice'] as String),
      bidQty: double.parse(json['bidQty'] as String),
      askPrice: double.parse(json['askPrice'] as String),
      askQty: double.parse(json['askQty'] as String),
    );
  }

  double get spread => askPrice - bidPrice;
  double get midPrice => (bidPrice + askPrice) / 2;
}

/// Average Price
class AvgPrice {
  final int mins;
  final double price;

  AvgPrice({required this.mins, required this.price});

  factory AvgPrice.fromJson(Map<String, dynamic> json) {
    return AvgPrice(
      mins: json['mins'] as int,
      price: double.parse(json['price'] as String),
    );
  }
}
