import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MiniSparkline extends StatelessWidget {
  const MiniSparkline({
    super.key,
    required this.values,
    this.strokeColor,
    this.fillColor,
  });

  final List<double> values;
  final Color? strokeColor;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final up = values.last >= values.first;

    final line = strokeColor ?? (up ? const Color(0xFF4CAF50) : const Color(0xFFE53935));
    final fill = fillColor ?? line;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            barWidth: 2,
            color: line,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  fill.withValues(alpha: 0.20),
                  fill.withValues(alpha: 0.06),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
