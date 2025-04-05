import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class StockAnalysisPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const StockAnalysisPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> stockData = data['stock_analysis'] ?? {};
    final Map<String, dynamic> pastAccuracy = data['past_accuracy'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Analysis'),
        backgroundColor: Colors.orange,
      ),
      body: ListView.builder(
        itemCount: stockData.length,
        itemBuilder: (context, index) {
          final symbol = stockData.keys.elementAt(index);
          final analysis = stockData[symbol];
          final bool? wasAccurate = pastAccuracy[symbol];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ExpansionTile(
                collapsedIconColor: Colors.blueGrey[800],
                iconColor: Colors.blueGrey[800],
                title: Text(
                  symbol,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                childrenPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                children: [
                  MarkdownBody(
                    data: analysis['brief_analysis'] ?? 'No analysis available',
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      Theme.of(context),
                    ).copyWith(
                      p: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        '📈 Recommendation: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        analysis['recommendation'] ?? 'N/A',
                        style: TextStyle(
                          color: _getColorForRecommendation(
                            analysis['recommendation'],
                          ),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (wasAccurate != null)
                    Row(
                      children: [
                        Tooltip(
                          message:
                              'Was our previous prediction for this stock correct based on actual market outcomes?',
                          child: const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '🧠 Past Prediction Accurate: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          wasAccurate ? '✅' : '❌',
                          style: TextStyle(
                            fontSize: 20,
                            color: wasAccurate ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getColorForRecommendation(String? rec) {
    switch (rec?.toLowerCase()) {
      case 'buy':
        return Colors.green;
      case 'sell':
        return Colors.red;
      case 'hold':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
