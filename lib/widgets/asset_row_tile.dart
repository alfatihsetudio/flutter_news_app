import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/asset_quote.dart';
import 'mini_line_chart.dart';
import 'percent_chip.dart';

class AssetRowTile extends StatelessWidget {
  const AssetRowTile({
    super.key,
    required this.item,
    required this.currency,
    required this.onTap,
    required this.onToggleWatch,
    this.isWatched = false,
  });

  final AssetQuote item;
  final String currency; // 'IDR' / 'USD'
  final VoidCallback onTap;
  final VoidCallback onToggleWatch;
  final bool isWatched;

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(locale: currency == 'IDR' ? 'id_ID' : 'en_US', symbol: currency == 'IDR' ? 'Rp ' : '\$ ');
    final priceStr = f.format(item.price);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // icon
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: CachedNetworkImage(
                imageUrl: item.image,
                width: 36, height: 36, fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const CircleAvatar(radius: 18, child: Icon(Icons.currency_bitcoin)),
              ),
            ),
            const SizedBox(width: 12),
            // name + symbol + percent
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item.name} (${item.symbol})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  PercentChip(value: item.change24h),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // sparkline kecil
            SizedBox(
              width: 80,
              height: 32,
              child: MiniLineChart(values: item.sparkline),
            ),
            const SizedBox(width: 12),
            // price + star
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(priceStr,
                    style: const TextStyle(
                      fontFeatures: [AssetQuote.tnumFeature],
                      fontWeight: FontWeight.w700,
                    )),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onToggleWatch,
                  icon: Icon(isWatched ? Icons.star_rounded : Icons.star_border_rounded,
                      color: isWatched ? Colors.amber : null),
                  tooltip: isWatched ? 'Remove watchlist' : 'Add watchlist',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
