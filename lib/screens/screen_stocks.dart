import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset_quote.dart';
import '../services/stocks_service.dart';
import '../widgets/asset_row_tile.dart';
import 'screen_stock_detail.dart';

class ScreenStocks extends StatefulWidget {
  const ScreenStocks({super.key});

  @override
  State<ScreenStocks> createState() => _ScreenStocksState();
}

class _ScreenStocksState extends State<ScreenStocks> with SingleTickerProviderStateMixin {
  final _svc = StocksService();
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  final _scrollCtrl = ScrollController();

  late TabController _tabCtrl;
  Timer? _timer;

  String _vs = 'idr'; // default IDR (1A)
  String get _currencyLabel => _vs.toUpperCase();

  List<AssetQuote> _all = [];
  Set<String> _watch = <String>{};
  bool _loading = false;
  String? _error;

  static const _refreshInterval = Duration(seconds: 10); // (2A)

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadWatchlist().then((_) => _loadData());
    _timer = Timer.periodic(_refreshInterval, (_) => _loadData(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWatchlist() async {
    final sp = await SharedPreferences.getInstance();
    _watch = (sp.getStringList('watchlist_assets') ?? const <String>[]).toSet();
    setState(() {});
  }

  Future<void> _saveWatchlist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList('watchlist_assets', _watch.toList());
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });
    try {
      final data = await _svc.fetchMarkets(vsCurrency: _vs, perPage: 50); // (3A)
      if (!mounted) return;
      setState(() {
        _all = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
      });
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    } finally {
      if (!mounted) return;
      if (!silent) setState(() => _loading = false);
    }
  }

  void _toggleWatch(String id) {
    setState(() {
      if (_watch.contains(id)) {
        _watch.remove(id);
      } else {
        _watch.add(id);
      }
    });
    _saveWatchlist();
  }

  List<AssetQuote> get _watchList => _all.where((e) => _watch.contains(e.id)).toList();

  List<AssetQuote> get _gainers {
    final list = [..._all];
    list.sort((a,b) => b.change24h.compareTo(a.change24h));
    return list.take(20).toList();
  }

  List<AssetQuote> get _losers {
    final list = [..._all];
    list.sort((a,b) => a.change24h.compareTo(b.change24h));
    return list.take(20).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Markets'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Markets'),
            Tab(text: 'Watchlist'),
            Tab(text: 'Movers'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _currencyLabel == 'IDR' ? 'Ganti ke USD' : 'Ganti ke IDR',
            onPressed: () {
              setState(() { _vs = _vs == 'idr' ? 'usd' : 'idr'; });
              _loadData();
            },
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: ShapeDecoration(
                shape: const StadiumBorder(),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Text(_currencyLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _loadData,
        child: _error != null
            ? ListView(
                children: [
                  const SizedBox(height: 60),
                  Center(child: Text('Terjadi kesalahan:\n$_error', textAlign: TextAlign.center)),
                  const SizedBox(height: 12),
                  Center(child: FilledButton(onPressed: _loadData, child: const Text('Coba lagi'))),
                ],
              )
            : TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildList(_all),
                  _buildList(_watchList, emptyText: 'Belum ada favorit.\nTap ★ pada aset di tab Markets.'),
                  _buildMovers(),
                ],
              ),
      ),
    );
  }

  Widget _buildList(List<AssetQuote> data, {String emptyText = 'Tidak ada data'}) {
    if (_loading && data.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    }
    if (data.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(child: Text(emptyText, textAlign: TextAlign.center)),
        ],
      );
    }
    return ListView.separated(
      controller: _scrollCtrl,
      itemCount: data.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final it = data[i];
        final watched = _watch.contains(it.id);
        return AssetRowTile(
          item: it,
          currency: _currencyLabel,
          isWatched: watched,
          onToggleWatch: () => _toggleWatch(it.id),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScreenStockDetail(
                  item: it,
                  currency: _currencyLabel,
                  isWatched: watched,
                  onToggleWatch: () {
                    _toggleWatch(it.id);
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMovers() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [Tab(text: 'Top Gainers'), Tab(text: 'Top Losers')]),
          Expanded(
            child: TabBarView(
              children: [
                _buildList(_gainers, emptyText: 'Belum ada data.'),
                _buildList(_losers, emptyText: 'Belum ada data.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
