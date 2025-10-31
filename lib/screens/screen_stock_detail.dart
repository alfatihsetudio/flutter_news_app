// lib/screens/screen_stock_detail.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/asset_quote.dart';
import '../widgets/percent_chip.dart';
import '../widgets/advanced_price_chart.dart'; // chart segmen hijau/merah + zoom

class ScreenStockDetail extends StatelessWidget {
  const ScreenStockDetail({
    super.key,
    required this.item,
    required this.currency,
    required this.onToggleWatch,
    required this.isWatched,
  });

  final AssetQuote item;
  final String currency; // "IDR" | "USD" dll
  final VoidCallback onToggleWatch;
  final bool isWatched;

  @override
  Widget build(BuildContext context) {
    final isIdr = currency.toUpperCase() == 'IDR';
    final f = NumberFormat.currency(
      locale: isIdr ? 'id_ID' : 'en_US',
      symbol: isIdr ? 'Rp ' : '\$ ',
      decimalDigits: 0,
    );

    final prices = item.sparkline.map((e) => (e as num).toDouble()).toList();
    final times = _buildTimesFor7d(prices.length);

    return Scaffold(
      appBar: AppBar(
        title: Text('${item.symbol} • Detail'),
        actions: [
          IconButton(
            onPressed: onToggleWatch,
            icon: Icon(
              isWatched ? Icons.star_rounded : Icons.star_border_rounded,
              color: isWatched ? Colors.amber : null,
            ),
            tooltip: isWatched ? 'Hapus dari Watchlist' : 'Tambah ke Watchlist',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              CircleAvatar(radius: 20, backgroundImage: NetworkImage(item.image)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              PercentChip(value: item.change24h),
            ],
          ),
          const SizedBox(height: 12),

          // Harga sekarang
          Text(
            f.format(item.price),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFeatures: [AssetQuote.tnumFeature],
            ),
          ),

          const SizedBox(height: 12),

          // ===== Chart utama (grid + label waktu + segmen hijau/merah + zoom/pan) =====
          SizedBox(
            height: 240,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: (prices.isNotEmpty && times.isNotEmpty && prices.length == times.length)
                    ? AdvancedPriceChart(prices: prices, times: times)
                    : const Center(child: Text('Grafik belum tersedia')),
              ),
            ),
          ),

          const SizedBox(height: 12),
          _statGrid(context, f),
        ],
      ),
    );
  }

  /// CoinGecko sparkline default: ~7 hari (nilai per beberapa menit).
  /// Generate timestamp merata untuk 7 hari ke belakang sesuai jumlah titik.
  List<DateTime> _buildTimesFor7d(int len) {
    if (len <= 0) return const [];
    if (len == 1) return [DateTime.now()];
    final start = DateTime.now().subtract(const Duration(days: 7));
    final totalMinutes = 7 * 24 * 60;
    return List.generate(len, (i) {
      final minute = (i * (totalMinutes - 1) / (len - 1)).round();
      return start.add(Duration(minutes: minute));
    });
  }

  Widget _statGrid(BuildContext ctx, NumberFormat f) {
    Widget cell(String t, String v) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t,
              style: TextStyle(color: Theme.of(ctx).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 4),
            Text(
              v,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontFeatures: [AssetQuote.tnumFeature],
              ),
            ),
          ],
        );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
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
            cell('24h High', f.format(item.high24h)),
            cell('24h Low', f.format(item.low24h)),
            cell('Market Cap', f.format(item.marketCap)),
            cell('Vol 24h', f.format(item.volume24h)),
          ],
        ),
      ),
    );
  }
}
