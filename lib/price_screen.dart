import 'package:flutter/material.dart';
import 'price_model.dart';
import 'price_service.dart';
import 'coin_card.dart';

class PriceScreen extends StatefulWidget {
  const PriceScreen({super.key});

  @override
  State<PriceScreen> createState() => _PriceScreenState();
}

class _PriceScreenState extends State<PriceScreen> {
  final PriceService _priceService = PriceService();
  final List<String> _symbols = [
    'BTCUSDT',
    'ETHUSDT',
    'SOLUSDT',
    'BNBUSDT',
    'ADAUSDT',
    'XRPUSDT',
    'LTCUSDT',
    'DOTUSDT',
    'AVAXUSDT',
    'MATICUSDT',
    'LINKUSDT',
    'ATOMUSDT',
  ];

  // Maps Symbol -> Open Price for selected range
  final Map<String, double> _openPrices = {};
  // Maps Symbol -> Sparkline data (last 24 close prices)
  final Map<String, List<double>> _sparklines = {};
  String _selectedFilter = '1D';
  bool _isLoadingPrices = true;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    await Future.wait([_fetchOpenPrices(), _fetchSparklines()]);
  }

  void _onFilterChanged(String filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
      _openPrices.clear();
      _sparklines.clear(); // Clear old sparklines too
      _isLoadingPrices = true;
    });
    _fetchOpenPrices();
    _fetchSparklines(); // Refresh sparklines for new filter
  }

  Future<void> _fetchOpenPrices() async {
    // Fetch all prices in parallel and batch the state update
    final Map<String, double> newPrices = {};

    await Future.wait(
      _symbols.map((symbol) async {
        try {
          final open = await _priceService.fetchOpenPriceForPeriod(
            symbol,
            _selectedFilter,
          );
          newPrices[symbol] = open;
        } catch (e) {
          debugPrint('Error fetching open price for $symbol: $e');
        }
      }),
    );

    // Single batched setState
    if (mounted) {
      setState(() {
        _openPrices.addAll(newPrices);
        _isLoadingPrices = false;
      });
    }
  }

  Future<void> _fetchSparklines() async {
    String interval;
    int limit;
    switch (_selectedFilter) {
      case '1H':
        interval = '1m';
        limit = 60;
        break;
      case '1D':
        interval = '1h';
        limit = 24;
        break;
      case '1W':
        interval = '4h';
        limit = 42;
        break;
      case '1M':
        interval = '1d';
        limit = 30;
        break;
      case '1Y':
        interval = '1w';
        limit = 52;
        break;
      default:
        interval = '1h';
        limit = 24;
    }

    // Fetch all sparklines in parallel and batch the state update
    final Map<String, List<double>> newSparklines = {};

    await Future.wait(
      _symbols.map((symbol) async {
        try {
          final candles = await _priceService.fetchCandles(
            symbol,
            interval: interval,
            limit: limit,
          );
          newSparklines[symbol] = candles.map((c) => c.close).toList();
        } catch (e) {
          debugPrint('Error fetching sparkline for $symbol: $e');
        }
      }),
    );

    // Single batched setState
    if (mounted) {
      setState(() => _sparklines.addAll(newSparklines));
    }
  }

  Future<void> _onRefresh() async {
    await _fetchAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'CRYPTO MARKET',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['1H', '1D', '1W', '1M', '1Y'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () => _onFilterChanged(filter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Coin List with Pull-to-Refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemCount: _symbols.length,
                separatorBuilder: (context, index) => const SizedBox(height: 0),
                itemBuilder: (context, index) {
                  final symbol = _symbols[index];
                  final sparkline = _sparklines[symbol];

                  return StreamBuilder<PriceTicker>(
                    stream: _priceService.getTickerStream(symbol),
                    builder: (context, snapshot) {
                      // Handle errors gracefully
                      if (snapshot.hasError) {
                        debugPrint(
                          'Stream error for $symbol: ${snapshot.error}',
                        );
                      }

                      if (snapshot.hasData) {
                        var ticker = snapshot.data!;

                        // Only show calculated percentage if not loading
                        if (!_isLoadingPrices &&
                            _openPrices.containsKey(symbol) &&
                            _openPrices[symbol]! > 0) {
                          final open = _openPrices[symbol]!;
                          final current = ticker.price;
                          final change = ((current - open) / open) * 100;

                          ticker = PriceTicker(
                            symbol: ticker.symbol,
                            price: ticker.price,
                            priceChangePercent: change,
                            highPrice: ticker.highPrice,
                            lowPrice: ticker.lowPrice,
                            volume: ticker.volume,
                            quoteVolume: ticker.quoteVolume,
                          );
                        } else if (_isLoadingPrices) {
                          ticker = PriceTicker(
                            symbol: ticker.symbol,
                            price: ticker.price,
                            priceChangePercent: double.nan,
                            highPrice: ticker.highPrice,
                            lowPrice: ticker.lowPrice,
                            volume: ticker.volume,
                            quoteVolume: ticker.quoteVolume,
                          );
                        }

                        return CoinCard(
                          ticker: ticker,
                          sparkline: sparkline,
                          isLoading: _isLoadingPrices,
                        );
                      }

                      // Fallback: fetch REST API data while waiting for WebSocket
                      return FutureBuilder<PriceTicker>(
                        future: _priceService.fetchTicker24h(symbol),
                        builder: (context, futureSnapshot) {
                          if (futureSnapshot.hasData) {
                            var ticker = futureSnapshot.data!;
                            // Apply percentage calculation for fallback too
                            if (!_isLoadingPrices &&
                                _openPrices.containsKey(symbol) &&
                                _openPrices[symbol]! > 0) {
                              final open = _openPrices[symbol]!;
                              final change =
                                  ((ticker.price - open) / open) * 100;
                              ticker = PriceTicker(
                                symbol: ticker.symbol,
                                price: ticker.price,
                                priceChangePercent: change,
                                highPrice: ticker.highPrice,
                                lowPrice: ticker.lowPrice,
                                volume: ticker.volume,
                                quoteVolume: ticker.quoteVolume,
                              );
                            }
                            return CoinCard(
                              ticker: ticker,
                              sparkline: sparkline,
                              isLoading: _isLoadingPrices,
                            );
                          }
                          return const SizedBox(
                            height: 100,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
