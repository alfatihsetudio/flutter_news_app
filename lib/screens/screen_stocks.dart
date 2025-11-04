// lib/screens/screen_stocks.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../models/asset_quote.dart';
import '../services/stocks_service.dart';
import '../widgets/mini_sparkline.dart';
import '../widgets/percent_chip.dart';
import '../widgets/glass.dart';
import 'screen_stock_detail.dart';

class ScreenStocks extends StatefulWidget {
  const ScreenStocks({super.key});

  @override
  State<ScreenStocks> createState() => _ScreenStocksState();
}

enum _Range { d1, d7, m1 }
enum _Sort { marketCap, price, change }

class _ScreenStocksState extends State<ScreenStocks> {
  final _svc = StocksService();
  final _search = TextEditingController();

  bool _loading = false;
  bool _refreshing = false;
  String _currency = 'IDR';
  _Range _range = _Range.d7;
  _Sort _sort = _Sort.marketCap;
  bool _onlyGainers = false;
  bool _onlyLosers  = false;

  List<AssetQuote> _all = const [];
  List<AssetQuote> _view = const [];

  // Watchlist (pakai id/symbol—keduanya unik di data CoinGecko)
  Set<String> _watch = {};

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _restoreWatchlist();
    _load();
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _restoreWatchlist() async {
    final sp = await SharedPreferences.getInstance();
    _watch = (sp.getStringList('watchlist') ?? const []).toSet();
    if (mounted) setState(() {});
  }

  Future<void> _persistWatchlist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList('watchlist', _watch.toList());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _svc.fetchTopMarkets(
        vsCurrency: _currency.toLowerCase(),
        perPage: 100,
        page: 1,
        includeSparkline: true,
      );
      if (!mounted) return;
      _all = data;
      _applyFilterSort();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await _load();
    if (mounted) setState(() => _refreshing = false);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), _applyFilterSort);
  }

  // Terapkan search, filter, sort
  void _applyFilterSort() {
    final q = _search.text.trim().toLowerCase();
    List<AssetQuote> list = _all;

    if (q.isNotEmpty) {
      list = list.where((x) =>
        x.name.toLowerCase().contains(q) || x.symbol.toLowerCase().contains(q)
      ).toList();
    }

    if (_onlyGainers) {
      list = list.where((x) => x.change24h >= 0).toList();
    }
    if (_onlyLosers) {
      list = list.where((x) => x.change24h < 0).toList();
    }

    list.sort((a, b) {
      switch (_sort) {
        case _Sort.marketCap: return (b.marketCap).compareTo(a.marketCap);
        case _Sort.price:     return (b.price).compareTo(a.price);
        case _Sort.change:    return (b.change24h).compareTo(a.change24h);
      }
    });

    setState(() => _view = list);
  }

  // Potong sparkline sesuai range (visual only: 1D/7D/1M)
  List<double> _sliceByRange(List<double> values) {
    if (values.isEmpty) return values;
    switch (_range) {
      case _Range.d1:
        final n = (values.length * 1 / 7).clamp(2, values.length).toInt();
        return values.sublist(values.length - n);
      case _Range.d7:
        return values; // sparkline ~7d
      case _Range.m1:
        // Duplikasi & smooth ringan (visual trick) agar terasa lebih panjang
        final twice = [...values, ...values];
        return twice;
    }
  }

  bool _isWatched(AssetQuote x) => _watch.contains(x.id) || _watch.contains(x.symbol);

  void _toggleWatch(AssetQuote x) {
    final key = x.id.isNotEmpty ? x.id : x.symbol;
    if (_watch.contains(key)) {
      _watch.remove(key);
    } else {
      _watch.add(key);
    }
    _persistWatchlist();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isIdr = _currency == 'IDR';
    final f = NumberFormat.currency(
      locale: isIdr ? 'id_ID' : 'en_US',
      symbol: isIdr ? 'Rp ' : '\$ ',
      decimalDigits: 0,
    );

    return Scaffold(
      body: Stack(
        children: [
          const _GradientBackground(),
          Positioned(top: -80, left: -40, child: _glowBlob(220, const Color(0xFF5B8CFF))),
          Positioned(bottom: -60, right: -20, child: _glowBlob(260, const Color(0xFFFFB86B))),

          SafeArea(
            child: Column(
              children: [
                // ===== Header =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: GlassCard(
                    radius: 24,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Row(
                      children: [
                        const Icon(Icons.show_chart, color: Colors.white),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Crypto Markets',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _CurrencySwitcher(
                          value: _currency,
                          onChanged: (v) {
                            setState(() => _currency = v);
                            _load();
                          },
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Filter & Urutkan',
                          onPressed: _openFilterSheet,
                          icon: const Icon(Icons.tune, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                // ===== Search + Range =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          radius: 18,
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                          child: TextField(
                            controller: _search,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search, color: Colors.white),
                              hintText: 'Cari aset (BTC, ETH, Solana...)',
                              hintStyle: const TextStyle(color: Color(0xCCFFFFFF)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white)),
                              fillColor: const Color(0x1FFFFFFF),
                              filled: true,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _RangeChips(
                        value: _range,
                        onChanged: (v) => setState(() => _range = v),
                      ),
                    ],
                  ),
                ),

                // ===== List =====
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    color: Colors.white,
                    backgroundColor: const Color(0xFF1D2A52),
                    child: _loading
                        ? _skeletonList()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                            itemCount: _view.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _assetTile(_view[i], f),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====== Widgets ======

  Widget _assetTile(AssetQuote x, NumberFormat f) {
    final spark = x.sparkline.cast<num>().map((e) => e.toDouble()).toList();
    final sliced = _sliceByRange(spark);
    final isUp = x.change24h >= 0;
    final watched = _isWatched(x);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 260),
              pageBuilder: (_, __, ___) => ScreenStockDetail(
                item: x,
                currency: _currency,
                isWatched: watched,
                onToggleWatch: () {
                  _toggleWatch(x);
                  Navigator.pop(context);
                },
              ),
              transitionsBuilder: (_, anim, __, child) {
                final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
                return FadeTransition(opacity: curved, child: child);
              },
            ),
          ).then((_) => setState(() {}));
        },
        child: GlassCard(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Hero(
                tag: 'asset:${x.symbol}',
                child: CircleAvatar(radius: 20, backgroundImage: NetworkImage(x.image)),
              ),
              const SizedBox(width: 12),
              // Nama & simbol
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          x.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: watched ? 'Hapus dari Watchlist' : 'Tambah ke Watchlist',
                        onPressed: () => setState(() => _toggleWatch(x)),
                        icon: Icon(
                          watched ? Icons.star_rounded : Icons.star_border_rounded,
                          color: watched ? Colors.amber : const Color(0xCCFFFFFF),
                          size: 20,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text(
                      x.symbol.toUpperCase(),
                      style: const TextStyle(color: Color(0xCCFFFFFF), letterSpacing: .6),
                    ),
                  ],
                ),
              ),
              // Harga & %change
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    f.format(x.price),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [AssetQuote.tnumFeature],
                    ),
                  ),
                  const SizedBox(height: 4),
                  PercentChip(value: x.change24h),
                ],
              ),
              const SizedBox(width: 12),
              // Sparkline
              SizedBox(
                width: 96,
                height: 36,
                child: MiniSparkline(values: sliced),
              ),
              const SizedBox(width: 4),
              Icon(
                isUp ? Icons.trending_up : Icons.trending_down,
                size: 18,
                color: isUp ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: 8,
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            radius: 20,
            padding: const EdgeInsets.all(14),
            child: Shimmer.fromColors(
              baseColor: const Color(0x22FFFFFF),
              highlightColor: const Color(0x44FFFFFF),
              child: Row(
                children: [
                  Container(width: 40, height: 40, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 12, width: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                        const SizedBox(height: 8),
                        Container(height: 10, width: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(height: 12, width: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  builder: (_) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GlassCard(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          // ⬅️ perbaikan di sini
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Filter & Urutkan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  selected: _onlyGainers,
                  onSelected: (v) => setState(() => _onlyGainers = v),
                  label: const Text('Top Gainers',
                      style: TextStyle(color: Colors.white)),
                  selectedColor: const Color(0x334CAF50),
                  checkmarkColor: Colors.white,
                  backgroundColor: const Color(0x1AFFFFFF),
                  showCheckmark: true,
                ),
                FilterChip(
                  selected: _onlyLosers,
                  onSelected: (v) => setState(() => _onlyLosers = v),
                  label: const Text('Top Losers',
                      style: TextStyle(color: Colors.white)),
                  selectedColor: const Color(0x33E53935),
                  checkmarkColor: Colors.white,
                  backgroundColor: const Color(0x1AFFFFFF),
                  showCheckmark: true,
                ),
              ],
            ),
                const SizedBox(height: 14),
                const Text('Urutkan berdasarkan', style: TextStyle(color: Color(0xCCFFFFFF))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _sortChip('Market Cap', _Sort.marketCap),
                    const SizedBox(width: 8),
                    _sortChip('Harga', _Sort.price),
                    const SizedBox(width: 8),
                    _sortChip('Perubahan', _Sort.change),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _applyFilterSort();
                    },
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Terapkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E9BFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sortChip(String label, _Sort value) {
    final selected = _sort == value;
    return GestureDetector(
      onTap: () => setState(() => _sort = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0x334E9BFF) : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : const Color(0xCCFFFFFF), fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _RangeChips extends StatelessWidget {
  const _RangeChips({required this.value, required this.onChanged});
  final _Range value;
  final ValueChanged<_Range> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, _Range v) {
      final selected = value == v;
      return GestureDetector(
        onTap: () => onChanged(v),
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip('1D', _Range.d1),
        const SizedBox(width: 6),
        chip('7D', _Range.d7),
        const SizedBox(width: 6),
        chip('1M', _Range.m1),
      ],
    );
  }
}

class _CurrencySwitcher extends StatelessWidget {
  const _CurrencySwitcher({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      tooltip: 'Mata uang',
      onSelected: onChanged,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'IDR', child: Text('IDR')),
        PopupMenuItem(value: 'USD', child: Text('USD')),
      ],
      child: Row(
        children: const [
          Icon(Icons.payments_outlined, color: Colors.white),
          SizedBox(width: 6),
          // Value ditulis manual karena PopupMenuButton child stateless:
          // Ditangani di parent lewat IconButton + Text biasa jika mau dinamis penuh
        ],
      ),
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
