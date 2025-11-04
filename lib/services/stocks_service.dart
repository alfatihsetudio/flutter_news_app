// lib/services/stocks_service.dart
import 'dart:convert';
import 'dart:io' show HttpHeaders;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/asset_quote.dart';

class StocksService {
  static const _base = 'https://api.coingecko.com/api/v3';

  /// Ambil daftar pasar (top coins) dengan sparkline.
  /// UI memanggil `fetchTopMarkets()`; method ini juga jadi basis alias lain.
  Future<List<AssetQuote>> fetchMarkets({
    String vsCurrency = 'idr',
    int perPage = 50,
    int page = 1,
    bool includeSparkline = true,
  }) async {
    final vs = _normalizeCurrency(vsCurrency);
    final rawUrl =
        '$_base/coins/markets'
        '?vs_currency=$vs'
        '&order=market_cap_desc'
        '&per_page=$perPage'
        '&page=$page'
        '&sparkline=$includeSparkline'
        '&price_change_percentage=24h';

    Object? lastError;

    // ---- 1) Direct call (Android/iOS oke; Web bisa CORS) ----
    try {
      final list = await _withRetry(() {
        return _getAndDecodeAsList(
          Uri.parse(rawUrl),
          headers: {
            HttpHeaders.acceptHeader: 'application/json',
            // Di Web, header ini akan diabaikan oleh browser (tidak masalah).
            HttpHeaders.userAgentHeader: 'flutter-stocks-demo/1.0',
          },
        );
      });
      return list.map((m) => AssetQuote.fromJson(m)).toList();
    } catch (e) {
      lastError = e;
    }

    // Kalau bukan Web, hentikan di sini dengan error asli
    if (!kIsWeb) {
      throw (lastError ?? Exception('Request failed (non-web).'));
    }

    // ---- 2) Web proxy: AllOrigins (RAW) ----
    try {
      final encoded = Uri.encodeComponent(rawUrl);
      final allOrigins = Uri.parse('https://api.allorigins.win/raw?url=$encoded');
      final list = await _withRetry(() => _getAndDecodeAsList(allOrigins));
      return list.map((m) => AssetQuote.fromJson(m)).toList();
    } catch (e) {
      lastError = e;
    }

    // ---- 3) Web proxy cadangan: isomorphic-git CORS ----
    try {
      final iso = Uri.parse('https://cors.isomorphic-git.org/$rawUrl');
      final list = await _withRetry(() => _getAndDecodeAsList(iso));
      return list.map((m) => AssetQuote.fromJson(m)).toList();
    } catch (e) {
      lastError = e;
      throw Exception('All attempts failed: $lastError');
    }
  }

  // -----------------------------
  // Alias agar UI lama tetap aman
  // -----------------------------

  /// Dipakai UI: ScreenStocks._load() → fetchTopMarkets()
  Future<List<AssetQuote>> fetchTopMarkets({
    String vsCurrency = 'idr',
    int perPage = 50,
    int page = 1,
    bool includeSparkline = true,
  }) {
    return fetchMarkets(
      vsCurrency: vsCurrency,
      perPage: perPage,
      page: page,
      includeSparkline: includeSparkline,
    );
    // NB: Kalau nanti mau dukung USD dari UI, tinggal kirim vsCurrency: 'USD'
  }

  /// Alias agar pemanggilan lama `fetchTopAssets()` tetap berfungsi.
  Future<List<AssetQuote>> fetchTopAssets({
    String vsCurrency = 'idr',
    int perPage = 50,
    int page = 1,
    bool includeSparkline = true,
  }) {
    return fetchMarkets(
      vsCurrency: vsCurrency,
      perPage: perPage,
      page: page,
      includeSparkline: includeSparkline,
    );
  }

  // ==========================
  // Helpers (HTTP & decoding)
  // ==========================

  String _normalizeCurrency(String c) {
    // Terima 'IDR' / 'Usd' / dll → 'idr' / 'usd'
    final s = (c.isEmpty ? 'idr' : c).toLowerCase().trim();
    return (s == 'usd' || s == 'idr') ? s : 'idr';
  }

  /// Retry sederhana: 3x percobaan untuk error jaringan/429/5xx.
  Future<T> _withRetry<T>(Future<T> Function() fn) async {
    const attempts = 3;
    Object? last;
    for (var i = 0; i < attempts; i++) {
      try {
        return await fn();
      } catch (e) {
        last = e;
        // kecilkan jeda backoff; cukup singkat agar UI responsif
        await Future.delayed(Duration(milliseconds: 250 * (i + 1)));
      }
    }
    throw last ?? Exception('Unknown error');
  }

  /// GET lalu pastikan ujungnya List<Map<String,dynamic>>
  Future<List<Map<String, dynamic>>> _getAndDecodeAsList(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

    // Hard fail untuk non-200 kecuali 304 (cache), walau CoinGecko biasanya 200
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    dynamic decoded;

    // Coba decode JSON langsung
    try {
      decoded = json.decode(res.body);
    } catch (_) {
      decoded = json.decode(res.body.toString());
    }

    // Kasus proxy AllOrigins (tanpa /raw) → { "contents": "....json string...." }
    if (decoded is Map && decoded['contents'] is String) {
      decoded = json.decode(decoded['contents'] as String);
    }

    // Beberapa proxy/wrapper membungkus di key "data"
    if (decoded is Map && decoded['data'] is List) {
      decoded = decoded['data'];
    }

    if (decoded is! List) {
      throw Exception('Unexpected payload shape (expecting List), got: ${decoded.runtimeType}');
    }

    // Pastikan setiap elemen berupa Map<String, dynamic>
    return decoded.map<Map<String, dynamic>>((e) {
      if (e is Map<String, dynamic>) return e;
      return Map<String, dynamic>.from(e as Map);
    }).toList();
  }
}
