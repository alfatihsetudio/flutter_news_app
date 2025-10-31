import 'dart:math';
import 'package:flutter/material.dart';

class MiniLineChart extends StatelessWidget {
  const MiniLineChart({super.key, required this.values, this.strokeWidth = 2.0});
  final List<num> values;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox.expand(child: Center(child: Text('-', style: TextStyle(fontSize: 12))));
    }
    return CustomPaint(
      painter: _SparkPainter(values.map((e) => e.toDouble()).toList(), strokeWidth),
      size: Size.infinite,
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.strokeWidth);
  final List<double> values;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final minV = values.reduce(min);
    final maxV = values.reduce(max);
    final span = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);

    // background guide
    final bg = Paint()..color = const Color(0x11000000);
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6));
    canvas.drawRRect(r, bg);

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final y = size.height - ((values[i] - minV) / span) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final up = values.last >= values.first;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = up ? const Color(0xFF16A34A) : const Color(0xFFDC2626)
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.strokeWidth != strokeWidth;
}
