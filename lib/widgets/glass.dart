// lib/widgets/glass.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class GlowBlob extends StatelessWidget {
  const GlowBlob({super.key, required this.size, required this.color, this.offset});
  final double size;
  final Color color;
  final Offset? offset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset ?? Offset.zero,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 40)],
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.radius = 20, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  static const Color _fill = Color(0x1AFFFFFF);   // ~10% white
  static const Color _stroke = Color(0x33FFFFFF); // ~20% white

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _fill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: _stroke),
          ),
          child: child,
        ),
      ),
    );
  }
}
