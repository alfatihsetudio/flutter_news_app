// lib/services/geocode_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_news_app/models/place.dart';

class GeocodeService {
  // Public Nominatim endpoint (for demo / low-traffic use only).
  // For production consider hosting your own instance or using a paid geocoding service.
  static const String _base = 'https://nominatim.openstreetmap.org';

  /// Search places using Nominatim.
  /// Returns a list of Place (may be empty).
  Future<List<Place>> search(String query, {int limit = 5}) async {
    if (query.trim().isEmpty) return <Place>[];

    final uri = Uri.parse('$_base/search').replace(queryParameters: {
      'q': query,
      'format': 'json',
      'limit': '$limit',
      'addressdetails': '1',
      // 'accept-language': 'id' // you can add preferred language if desired
    });

    final headers = {
      'Accept': 'application/json',
      // Replace with your app name / contact before publishing publicly.
      'User-Agent': kIsWeb ? 'flutter-news-app-web/1.0' : 'flutter-news-app/1.0 (your_email@example.com)',
    };

    try {
      final resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final List<dynamic> arr = json.decode(resp.body) as List<dynamic>;
        return arr.map((e) => Place.fromNominatimJson(e as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Geocode search failed (status ${resp.statusCode})');
      }
    } catch (e) {
      // Re-throw as Exception so callers can show UI error
      throw Exception('Geocode search error: $e');
    }
  }

  /// Reverse geocoding: get a human-readable address for lat/lon.
  /// Returns Place or null if failed.
  Future<Place?> reverse(double lat, double lon) async {
    final uri = Uri.parse('$_base/reverse').replace(queryParameters: {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'format': 'json',
      'addressdetails': '1',
    });

    final headers = {
      'Accept': 'application/json',
      'User-Agent': kIsWeb ? 'flutter-news-app-web/1.0' : 'flutter-news-app/1.0 (your_email@example.com)',
    };

    try {
      final resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final Map<String, dynamic> j = json.decode(resp.body) as Map<String, dynamic>;
        // Nominatim reverse returns a slightly different shape than search.
        final display = (j['display_name'] ?? '').toString();
        final latRes = double.tryParse((j['lat'] ?? lat).toString()) ?? lat;
        final lonRes = double.tryParse((j['lon'] ?? lon).toString()) ?? lon;
        final id = j['place_id']?.toString() ?? '${latRes.toStringAsFixed(6)},${lonRes.toStringAsFixed(6)}';
        return Place(
          id: id,
          name: display.split(',').first,
          displayName: display,
          lat: latRes,
          lon: lonRes,
          type: j['type']?.toString(),
        );
      } else {
        return null;
      }
    } catch (e) {
      // For reverse, return null on error (caller can decide)
      return null;
    }
  }
}
