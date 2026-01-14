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
  ];

  // Maps Symbol -> Open Price for selected range
  final Map<String, double> _openPrices = {};
  String _selectedFilter = '1D';

  @override
  void initState() {
    super.initState();
    _fetchOpenPrices(); // Initial fetch for 1D
  }

  void _onFilterChanged(String filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
      _openPrices.clear(); // Clear old prices to show loading or fallback
    });
    _fetchOpenPrices();
  }

  Future<void> _fetchOpenPrices() async {
    for (final symbol in _symbols) {
      try {
        final open = await _priceService.fetchOpenPriceForPeriod(
          symbol,
          _selectedFilter,
        );
        if (mounted) {
          setState(() {
            _openPrices[symbol] = open;
          });
        }
      } catch (e) {
        debugPrint('Error fetching open price for $symbol: $e');
      }
    }
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
              children: ['1H', '1D', '1W', '1M'].map((filter) {
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

          // Coin List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: _symbols.length,
              separatorBuilder: (context, index) => const SizedBox(height: 0),
              itemBuilder: (context, index) {
                final symbol = _symbols[index];

                return StreamBuilder<PriceTicker>(
                  stream: _priceService.getTickerStream(symbol),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      // Inject our calculated change percent if available
                      var ticker = snapshot.data!;
                      if (_openPrices.containsKey(symbol) &&
                          _openPrices[symbol]! > 0) {
                        final open = _openPrices[symbol]!;
                        final current = ticker.price;
                        final change = ((current - open) / open) * 100;

                        // Create a modified ticker for display
                        // Using a copyWith-like approach manually here as we didn't add copyWith
                        ticker = PriceTicker(
                          symbol: ticker.symbol,
                          price: ticker.price,
                          priceChangePercent:
                              change, // Overwrite with filter range change
                          highPrice: ticker.highPrice,
                          lowPrice: ticker.lowPrice,
                          volume: ticker.volume,
                          quoteVolume: ticker.quoteVolume,
                        );
                      }

                      return CoinCard(ticker: ticker);
                    }

                    // Fallback
                    return FutureBuilder<PriceTicker>(
                      future: _priceService.fetchTicker24h(symbol),
                      builder: (context, futureSnapshot) {
                        if (futureSnapshot.hasData) {
                          return CoinCard(ticker: futureSnapshot.data!);
                        }
                        return const SizedBox(
                          height: 80,
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
        ],
      ),
    );
  }
}
