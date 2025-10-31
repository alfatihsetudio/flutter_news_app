import 'dart:convert';
import 'dart:io' show HttpHeaders;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/asset_quote.dart';

class StocksService {
  static const _base = 'https://api.coingecko.com/api/v3';

  Future<List<AssetQuote>> fetchMarkets({
    String vsCurrency = 'idr',
    int perPage = 50,
    int page = 1,
    bool includeSparkline = true,
  }) async {
    final rawUrl =
        '$_base/coins/markets'
        '?vs_currency=$vsCurrency'
        '&order=market_cap_desc'
        '&per_page=$perPage'
        '&page=$page'
        '&sparkline=$includeSparkline'
        '&price_change_percentage=24h';

    Object? lastError;

    // 1) Coba direct (Android/iOS aman; Web bisa CORS)
    try {
      final list = await _getAndDecodeAsList(
        Uri.parse(rawUrl),
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.userAgentHeader: 'flutter-stocks-demo/1.0',
        },
      );
      return list.map((m) => AssetQuote.fromJson(m)).toList();
    } catch (e) {
      lastError = e; // simpan error
    }

    // Kalau bukan Web, hentikan di sini dengan error asli
    if (!kIsWeb) {
      throw (lastError ?? Exception('Request failed (non-web).'));
    }

    // 2) Web proxy: AllOrigins (raw)
    try {
      final encoded = Uri.encodeComponent(rawUrl);
      final allOrigins = Uri.parse('https://api.allorigins.win/raw?url=$encoded');
      final list = await _getAndDecodeAsList(allOrigins);
      return list.map((m) => AssetQuote.fromJson(m)).toList();
    } catch (e) {
      lastError = e;
    }

    // 3) Web proxy cadangan: isomorphic-git CORS
    try {
      final iso = Uri.parse('https://cors.isomorphic-git.org/$rawUrl');
      final list = await _getAndDecodeAsList(iso);
      return list.map((m) => AssetQuote.fromJson(m)).toList();
    } catch (e) {
      lastError = e;
      throw Exception('All attempts failed: $lastError');
    }
  }

  /// Ambil HTTP lalu pastikan hasil akhirnya adalah List<Map<String, dynamic>>
  Future<List<Map<String, dynamic>>> _getAndDecodeAsList(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

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

    // Kasus proxy AllOrigins TANPA /raw → { "contents": "....json string...." }
    if (decoded is Map && decoded['contents'] is String) {
      decoded = json.decode(decoded['contents'] as String);
    }

    // Beberapa proxy membungkus di key "data"
    if (decoded is Map && decoded['data'] is List) {
      decoded = decoded['data'];
    }

    if (decoded is! List) {
      throw Exception('Unexpected payload shape (expecting List), got: ${decoded.runtimeType}');
    }

    // Pastikan setiap elemen map
    return decoded.map<Map<String, dynamic>>((e) {
      if (e is Map<String, dynamic>) return e;
      return Map<String, dynamic>.from(e as Map);
    }).toList();
  }
}
