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
  double _rangeOpenPrice = 0.0; // For consistent % calculation with homepage

  // 24h Ticker for stats (fetched once)
  PriceTicker? _ticker24h;

  @override
  void initState() {
    super.initState();
    _priceStream = _priceService.getTickerStream(widget.symbol);
    _fetchTicker24h(); // Fetch full 24h ticker for stats
    _fetchChartData('1h', 24); // Default 1D
    _fetch1HChange();
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
    // 1H change is specifically asked for.
    // We can fetch the open price of 1h ago.
    try {
      final open = await _priceService.fetchOpenPriceForPeriod(
        widget.symbol,
        '1H',
      );
      if (mounted) {
        setState(() {
          _1hOpenPrice = open;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  double _1hOpenPrice = 0.0;

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

          // Dynamic Range Change
          double percent = 0.0;
          if (_candles.isNotEmpty && price > 0) {
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
                              titlesData: const FlTitlesData(show: false),
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
              ],
            ),
          );
        },
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
