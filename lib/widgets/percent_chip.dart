import 'package:flutter/material.dart';

class PercentChip extends StatelessWidget {
  const PercentChip({super.key, required this.value});
  final num value;

  @override
  Widget build(BuildContext context) {
    final up = value >= 0;
    final color = up ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final icon = up ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded;
    final text = '${value.toStringAsFixed(2)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.10),
        shape: StadiumBorder(side: BorderSide(color: color.withValues(alpha: 0.25))),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 2),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
