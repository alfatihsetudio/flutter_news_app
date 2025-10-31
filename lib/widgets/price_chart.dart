import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PriceChart extends StatelessWidget {
  const PriceChart({
    super.key,
    required this.prices,
    required this.times, // harus sama panjang dengan prices
  });

  final List<double> prices;
  final List<DateTime> times;

  @override
  Widget build(BuildContext context) {
    if (prices.isEmpty || times.isEmpty || prices.length != times.length) {
      return const Center(child: Text('No data'));
    }

    final minY = prices.reduce((a, b) => a < b ? a : b);
    final maxY = prices.reduce((a, b) => a > b ? a : b);
    final spanY = (maxY - minY).abs() < 1e-9 ? 1.0 : (maxY - minY);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (prices.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,

        // GRID
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          verticalInterval: (prices.length / 6).clamp(1, double.infinity),
          horizontalInterval: (spanY / 4),
          getDrawingVerticalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.25), strokeWidth: 0.6),
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.25), strokeWidth: 0.6),
        ),

        // TITLES (waktu di bawah, harga di kiri)
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: spanY / 4,
              getTitlesWidget: (value, _) => Text(
                value.toStringAsFixed(0),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (prices.length / 6).clamp(1, double.infinity),
              getTitlesWidget: (value, _) {
                final i = value.toInt().clamp(0, times.length - 1);
                final t = times[i];
                final label = '${t.month}/${t.day} ${t.hour.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(label, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),

        // TOOLTIP (sentuh untuk lihat waktu & harga)
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final i = s.x.toInt().clamp(0, times.length - 1);
              final t = times[i];
              final timeStr = '${t.year}-${t.month.toString().padLeft(2,'0')}-${t.day.toString().padLeft(2,'0')} '
                              '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
              return LineTooltipItem(
                'Rp ${s.y.toStringAsFixed(0)}\n$timeStr',
                const TextStyle(fontWeight: FontWeight.w700),
              );
            }).toList(),
          ),
        ),

        // GARIS CHART
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            barWidth: 2.2,
            color: Colors.blue,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.18)),
            spots: List.generate(
              prices.length,
              (i) => FlSpot(i.toDouble(), prices[i]),
            ),
          ),
        ],
      ),
    );
  }
}
