import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'price_model.dart';
import 'price_service.dart';

class CoinDetailScreen extends StatefulWidget {
  final String symbol;

  const CoinDetailScreen({super.key, required this.symbol});

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  final PriceService _priceService = PriceService();
  late Stream<PriceTicker> _priceStream;
  List<Candle> _candles = [];
  bool _isLoadingChart = true;
  String _selectedRange = '1D';

  // Stat placeholders
  double _rangeHigh = 0.0;
  double _rangeLow = 0.0;
  double _rangeOpenPrice = 0.0;

  // 24h Ticker for stats
  PriceTicker? _ticker24h;

  // New data
  OrderBook? _orderBook;
  List<Trade> _trades = [];
  BookTicker? _bookTicker;
  AvgPrice? _avgPrice;
  double _1hOpenPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _priceStream = _priceService.getTickerStream(widget.symbol);
    _fetchTicker24h();
    _fetchChartData('1h', 24);
    _fetchRangeOpenPrice('1D');
    _fetch1HChange();
    _fetchOrderBook();
    _fetchTrades();
    _fetchBookTicker();
    _fetchAvgPrice();
  }

  Future<void> _fetchTicker24h() async {
    try {
      final ticker = await _priceService.fetchTicker24h(widget.symbol);
      if (mounted) {
        setState(() => _ticker24h = ticker);
      }
    } catch (e) {
      debugPrint('Error fetching 24h ticker: $e');
    }
  }

  Future<void> _fetch1HChange() async {
    try {
      final open = await _priceService.fetchOpenPriceForPeriod(
        widget.symbol,
        '1H',
      );
      if (mounted) {
        setState(() => _1hOpenPrice = open);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _fetchOrderBook() async {
    try {
      final book = await _priceService.fetchOrderBook(widget.symbol, limit: 10);
      if (mounted) setState(() => _orderBook = book);
    } catch (e) {
      debugPrint('Error fetching order book: $e');
    }
  }

  Future<void> _fetchTrades() async {
    try {
      final trades = await _priceService.fetchRecentTrades(
        widget.symbol,
        limit: 15,
      );
      if (mounted) setState(() => _trades = trades.reversed.toList());
    } catch (e) {
      debugPrint('Error fetching trades: $e');
    }
  }

  Future<void> _fetchBookTicker() async {
    try {
      final bt = await _priceService.fetchBookTicker(widget.symbol);
      if (mounted) setState(() => _bookTicker = bt);
    } catch (e) {
      debugPrint('Error fetching book ticker: $e');
    }
  }

  Future<void> _fetchAvgPrice() async {
    try {
      final ap = await _priceService.fetchAvgPrice(widget.symbol);
      if (mounted) setState(() => _avgPrice = ap);
    } catch (e) {
      debugPrint('Error fetching avg price: $e');
    }
  }

  void _onRangeSelected(String range) {
    if (_selectedRange == range) return;
    setState(() {
      _selectedRange = range;
      _isLoadingChart = true;
    });

    // Fetch open price for percentage calculation (same as homepage)
    _fetchRangeOpenPrice(range);

    switch (range) {
      case '1D':
        _fetchChartData('1h', 24);
        break;
      case '1W':
        _fetchChartData('4h', 42);
        break;
      case '1M':
        _fetchChartData('1d', 30);
        break;
      case '1Y':
        _fetchChartData('1w', 52);
        break;
    }
  }

  Future<void> _fetchRangeOpenPrice(String range) async {
    try {
      final open = await _priceService.fetchOpenPriceForPeriod(
        widget.symbol,
        range,
      );
      if (mounted) {
        setState(() => _rangeOpenPrice = open);
      }
    } catch (e) {
      debugPrint('Error fetching range open price: $e');
    }
  }

  Future<void> _fetchChartData(String interval, int limit) async {
    try {
      final candles = await _priceService.fetchCandles(
        widget.symbol,
        interval: interval,
        limit: limit,
      );
      if (mounted) {
        setState(() {
          _candles = candles;
          if (candles.isNotEmpty) {
            _rangeHigh = candles
                .map((c) => c.high)
                .reduce((a, b) => a > b ? a : b);
            _rangeLow = candles
                .map((c) => c.low)
                .reduce((a, b) => a < b ? a : b);
          }
          _isLoadingChart = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching chart: $e');
      if (mounted) setState(() => _isLoadingChart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('${widget.symbol} Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<PriceTicker>(
        stream: _priceStream,
        builder: (context, snapshot) {
          final ticker = snapshot.data;
          final price = ticker?.price ?? 0.0;

          // Dynamic Range Change - use _rangeOpenPrice for consistency with homepage
          double percent = 0.0;
          if (_rangeOpenPrice > 0 && price > 0) {
            percent = ((price - _rangeOpenPrice) / _rangeOpenPrice) * 100;
          } else if (_candles.isNotEmpty && price > 0) {
            // Fallback to chart candles if rangeOpenPrice not yet loaded
            final openPrice = _candles.first.open;
            if (openPrice != 0)
              percent = ((price - openPrice) / openPrice) * 100;
          } else {
            percent = ticker?.priceChangePercent ?? 0.0;
          }

          // 1H Change specific
          double change1H = 0.0;
          if (_1hOpenPrice > 0 && price > 0) {
            change1H = ((price - _1hOpenPrice) / _1hOpenPrice) * 100;
          }

          final isPositive = percent >= 0;
          final color = isPositive ? Colors.green : Colors.red;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Header
                Text(
                  '\$${price > 0 ? (price > 10 ? price.toStringAsFixed(2) : price.toStringAsPrecision(4)) : '...'}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text:
                            '${isPositive ? '+' : ''}${percent.toStringAsFixed(2)}% ',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: '($_selectedRange)'),
                    ],
                  ),
                ),
                if (change1H != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '1H Change: ${change1H >= 0 ? '+' : ''}${change1H.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: change1H >= 0 ? Colors.green : Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Chart
                SizedBox(
                  height: 300,
                  child: _isLoadingChart
                      ? const Center(child: CircularProgressIndicator())
                      : _candles.isEmpty
                      ? const Center(child: Text('No chart data'))
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 22,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 || index >= _candles.length)
                                        return const SizedBox();

                                      final date =
                                          DateTime.fromMillisecondsSinceEpoch(
                                            _candles[index].openTime,
                                          );
                                      String text;

                                      // Simple formatting based on range
                                      if (_selectedRange == '1D') {
                                        // HH:mm for 1D
                                        text =
                                            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                                      } else if (_selectedRange == '1W' ||
                                          _selectedRange == '1M') {
                                        // MM/dd for 1W/1M
                                        text = '${date.month}/${date.day}';
                                      } else {
                                        // MM/yy for 1Y
                                        text =
                                            '${date.month}/${date.year.toString().substring(2)}';
                                      }

                                      // Show fewer labels to avoid overlapping
                                      // Logic: show label if index is multiple of (length / 5) roughly
                                      int interval = (_candles.length / 5)
                                          .ceil();
                                      if (interval < 1) interval = 1;

                                      if (index % interval != 0)
                                        return const SizedBox();

                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(
                                          text,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withOpacity(0.5),
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    },
                                    interval:
                                        1, // Draw titles at all intervals, filter in getTitlesWidget
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: _candles.length.toDouble() - 1,
                              minY:
                                  _candles
                                      .map((c) => c.low)
                                      .reduce((a, b) => a < b ? a : b) *
                                  0.999, // Tight fit
                              maxY:
                                  _candles
                                      .map((c) => c.high)
                                      .reduce((a, b) => a > b ? a : b) *
                                  1.001,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _candles
                                      .asMap()
                                      .entries
                                      .map(
                                        (e) => FlSpot(
                                          e.key.toDouble(),
                                          e.value.close,
                                        ),
                                      )
                                      .toList(),
                                  isCurved: true,
                                  color: color,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        color.withOpacity(0.3),
                                        color.withOpacity(0.0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                              lineTouchData: LineTouchData(
                                enabled: true,
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      final candle = _candles[spot.spotIndex];
                                      return LineTooltipItem(
                                        '\$${candle.close > 10 ? candle.close.toStringAsFixed(2) : candle.close.toStringAsPrecision(4)}\nO: ${candle.open.toStringAsFixed(2)}\nH: ${candle.high.toStringAsFixed(2)}\nL: ${candle.low.toStringAsFixed(2)}',
                                        TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                                getTouchedSpotIndicator: (data, spotIndexes) {
                                  return spotIndexes.map((index) {
                                    return TouchedSpotIndicatorData(
                                      FlLine(
                                        color: color.withOpacity(0.5),
                                        strokeWidth: 1,
                                      ),
                                      FlDotData(
                                        show: true,
                                        getDotPainter:
                                            (spot, percent, barData, index) {
                                              return FlDotCirclePainter(
                                                radius: 4,
                                                color: color,
                                                strokeWidth: 0,
                                              );
                                            },
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Range Filters
                Container(
                  padding: const EdgeInsets.all(4),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['1D', '1W', '1M', '1Y'].map((range) {
                      final selected = _selectedRange == range;
                      return GestureDetector(
                        onTap: () => _onRangeSelected(range),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Theme.of(context).cardColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            range,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: selected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),

                // Market Stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Market Stats',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatGrid(_ticker24h),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Extended Stats (Bid/Ask, Avg Price)
                if (_bookTicker != null || _avgPrice != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Extended Stats',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            if (_bookTicker != null) ...[
                              _buildStatItem('Best Bid', _bookTicker!.bidPrice),
                              _buildStatItem('Best Ask', _bookTicker!.askPrice),
                              _buildStatItem('Spread', _bookTicker!.spread),
                            ],
                            if (_avgPrice != null)
                              _buildStatItem(
                                'Avg Price (${_avgPrice!.mins}m)',
                                _avgPrice!.price,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),

                // Order Book
                if (_orderBook != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Book',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildOrderBookSide(
                                _orderBook!.bids,
                                'Bids',
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildOrderBookSide(
                                _orderBook!.asks,
                                'Asks',
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),

                // Recent Trades
                if (_trades.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Trades',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...(_trades
                            .take(10)
                            .map((trade) => _buildTradeRow(trade))),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderBookSide(
    List<OrderBookEntry> entries,
    String title,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...entries
            .take(5)
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.price > 10
                          ? e.price.toStringAsFixed(2)
                          : e.price.toStringAsPrecision(4),
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                    Text(
                      e.quantity.toStringAsFixed(4),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildTradeRow(Trade trade) {
    final color = trade.isBuy ? Colors.green : Colors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            trade.isBuy ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            trade.price > 10
                ? trade.price.toStringAsFixed(2)
                : trade.price.toStringAsPrecision(4),
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            trade.qty.toStringAsFixed(4),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(PriceTicker? ticker) {
    if (ticker == null) return const Center(child: CircularProgressIndicator());

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatItem('High (24h)', ticker.highPrice),
        _buildStatItem('Low (24h)', ticker.lowPrice),
        _buildStatItem('Volume (Base)', ticker.volume, isCurrency: false),
        _buildStatItem('Volume (Quote)', ticker.quoteVolume),
        // Range stats from candles
        _buildStatItem('Range High', _rangeHigh),
        _buildStatItem('Range Low', _rangeLow),
      ],
    );
  }

  Widget _buildStatItem(String label, double val, {bool isCurrency = true}) {
    String value = '-';
    if (val > 0) {
      if (val > 1000000) {
        value = '${(val / 1000000).toStringAsFixed(2)}M';
      } else if (val > 1000) {
        value = val.toStringAsFixed(2);
      } else {
        value = val.toStringAsFixed(4);
      }
      if (isCurrency) value = '\$$value';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
