// lib/screens/screen_stock_detail.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/asset_quote.dart';
import '../widgets/percent_chip.dart';
import '../widgets/glass.dart';
import '../widgets/advanced_price_chart.dart';

class ScreenStockDetail extends StatefulWidget {
  const ScreenStockDetail({
    super.key,
    required this.item,
    required this.currency,
    required this.onToggleWatch,
    required this.isWatched,
  });

  final AssetQuote item;
  final String currency; // 'IDR' | 'USD'
  final VoidCallback onToggleWatch;
  final bool isWatched;

  @override
  State<ScreenStockDetail> createState() => _ScreenStockDetailState();
}

class _ScreenStockDetailState extends State<ScreenStockDetail> {
  String _range = '7D'; // 1D / 7D / 1M

  @override
  Widget build(BuildContext context) {
    final isIdr = widget.currency.toUpperCase() == 'IDR';
    final f = NumberFormat.currency(
      locale: isIdr ? 'id_ID' : 'en_US',
      symbol: isIdr ? 'Rp ' : '\$ ',
      decimalDigits: 0,
    );

    final base = widget.item.sparkline.cast<num>().map((e) => e.toDouble()).toList();
    final prices = _sliceByRange(base, _range);
    final times  = _buildTimesFor7d(prices.length, range: _range);

    return Scaffold(
      body: Stack(
        children: [
          const _GradientBackground(),
          Positioned(top: -80, left: -40, child: _glowBlob(220, const Color(0xFF5B8CFF))),
          Positioned(bottom: -60, right: -20, child: _glowBlob(260, const Color(0xFFFFB86B))),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Text(widget.item.symbol.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                      onPressed: widget.onToggleWatch,
                      tooltip: widget.isWatched ? 'Hapus dari Watchlist' : 'Tambah ke Watchlist',
                      icon: Icon(
                        widget.isWatched ? Icons.star_rounded : Icons.star_border_rounded,
                        color: widget.isWatched ? Colors.amber : Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                GlassCard(
                  radius: 24,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'asset:${widget.item.symbol}',
                        child: CircleAvatar(radius: 26, backgroundImage: NetworkImage(widget.item.image)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.item.name,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(widget.item.symbol.toUpperCase(), style: const TextStyle(color: Color(0xCCFFFFFF))),
                                const SizedBox(width: 8),
                                PercentChip(value: widget.item.change24h),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Harga + range selector
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        f.format(widget.item.price),
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [AssetQuote.tnumFeature],
                        ),
                      ),
                    ),
                    _rangeChip('1D'), const SizedBox(width: 6),
                    _rangeChip('7D'), const SizedBox(width: 6),
                    _rangeChip('1M'),
                  ],
                ),
                const SizedBox(height: 12),

                GlassCard(
                  radius: 24,
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                  child: SizedBox(
                    height: 300,
                    child: prices.isEmpty
                        ? const Center(child: Text('Grafik belum tersedia', style: TextStyle(color: Colors.white)))
                        : AdvancedPriceChart(prices: prices, times: times),
                  ),
                ),
                const SizedBox(height: 14),

                GlassCard(
                  radius: 24,
                  padding: const EdgeInsets.all(12),
                  child: GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 56,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    children: [
                      _cell('24h High', f.format(widget.item.high24h)),
                      _cell('24h Low',  f.format(widget.item.low24h)),
                      _cell('Market Cap', f.format(widget.item.marketCap)),
                      _cell('Vol 24h', f.format(widget.item.volume24h)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==== helpers ====

  List<double> _sliceByRange(List<double> v, String range) {
    if (v.isEmpty) return v;
    switch (range) {
      case '1D':
        final n = (v.length * 1 / 7).clamp(2, v.length).toInt();
        return v.sublist(v.length - n);
      case '7D':
        return v;
      case '1M':
        return [...v, ...v]; // visual extend
      default:
        return v;
    }
  }

  List<DateTime> _buildTimesFor7d(int len, {required String range}) {
    if (len <= 0) return const [];
    Duration span;
    switch (range) {
      case '1D': span = const Duration(days: 1); break;
      case '1M': span = const Duration(days: 30); break;
      default:   span = const Duration(days: 7);
    }
    final start = DateTime.now().subtract(span);
    final totalMinutes = span.inMinutes;
    return List.generate(len, (i) {
      final minute = (i * (totalMinutes - 1) / (len - 1)).round();
      return start.add(Duration(minutes: minute));
    });
  }

  Widget _rangeChip(String label) {
    final selected = _range == label;
    return GestureDetector(
      onTap: () => setState(() => _range = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0x334E9BFF) : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : const Color(0xCCFFFFFF), fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _cell(String t, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        Text(t, style: const TextStyle(color: Color(0xCCFFFFFF))),
        const SizedBox(height: 4),
        Text(
          v,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFeatures: [AssetQuote.tnumFeature],
          ),
        ),
      ],
    );
  }
}

class _GradientBackground extends StatelessWidget {
  const _GradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0E1630), Color(0xFF1D2A52), Color(0xFF22345F), Color(0xFF19203D)],
        ),
      ),
    );
  }
}

Widget _glowBlob(double size, Color color) {
  return Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 40)],
    ),
  );
}
