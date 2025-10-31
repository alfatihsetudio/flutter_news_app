import 'dart:ui';

class AssetQuote {
  final String id;
  final String symbol;
  final String name;
  final String image;
  final num price; // current_price
  final num change24h; // price_change_percentage_24h (persen)
  final num marketCap;
  final num volume24h;
  final num high24h;
  final num low24h;
  final List<num> sparkline; // 7d sparkline

  const AssetQuote({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.price,
    required this.change24h,
    required this.marketCap,
    required this.volume24h,
    required this.high24h,
    required this.low24h,
    required this.sparkline,
  });

  factory AssetQuote.fromJson(Map<String, dynamic> j) {
    final spark = (j['sparkline_in_7d']?['price'] as List?)?.cast<num>() ?? const <num>[];
    return AssetQuote(
      id: j['id'] ?? '',
      symbol: (j['symbol'] ?? '').toString().toUpperCase(),
      name: j['name'] ?? '',
      image: j['image'] ?? '',
      price: j['current_price'] ?? 0,
      change24h: (j['price_change_percentage_24h'] ?? 0) as num,
      marketCap: j['market_cap'] ?? 0,
      volume24h: j['total_volume'] ?? 0,
      high24h: j['high_24h'] ?? 0,
      low24h: j['low_24h'] ?? 0,
      sparkline: spark,
    );
  }

  bool get isUp => change24h >= 0;

  // bantu typography angka sejajar
  static const tnumFeature = FontFeature.tabularFigures();
}
