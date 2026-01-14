import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'price_model.dart';
import 'coin_detail_screen.dart';

class CoinCard extends StatelessWidget {
  final PriceTicker ticker;
  final List<double>? sparkline;
  final bool isLoading;

  const CoinCard({
    super.key,
    required this.ticker,
    this.sparkline,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Handle NaN and loading state for color determination
    final percent = ticker.priceChangePercent;
    final isPositive = !percent.isNaN && percent >= 0;
    final color = isLoading
        ? Colors.grey
        : (isPositive ? Colors.green : Colors.red);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CoinDetailScreen(symbol: ticker.symbol),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    // Coin Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          ticker.symbol.substring(0, 1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Coin Name
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticker.symbol.replaceAll('USDT', ''),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            ticker.symbol,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Mini Sparkline Chart
                    if (sparkline != null && sparkline!.length > 1)
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 40,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: (sparkline!.length - 1).toDouble(),
                              minY:
                                  sparkline!.reduce((a, b) => a < b ? a : b) *
                                  0.999,
                              maxY:
                                  sparkline!.reduce((a, b) => a > b ? a : b) *
                                  1.001,
                              lineTouchData: const LineTouchData(
                                enabled: false,
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: sparkline!
                                      .asMap()
                                      .entries
                                      .map(
                                        (e) =>
                                            FlSpot(e.key.toDouble(), e.value),
                                      )
                                      .toList(),
                                  isCurved: true,
                                  color: color,
                                  barWidth: 1.5,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        color.withOpacity(0.2),
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

                    const SizedBox(width: 12),

                    // Price and Change
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${ticker.price > 10 ? ticker.price.toStringAsFixed(2) : ticker.price.toStringAsPrecision(4)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 40,
                                  height: 14,
                                  child: Center(
                                    child: SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  '${isPositive ? '+' : ''}${ticker.priceChangePercent.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
