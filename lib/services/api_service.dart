// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/article.dart';
import '../constants.dart';

class ApiService {
  final String _apiKey = NEWS_API_KEY;

  String _wrapWithProxyIfNeeded(String originalUrl) {
    if (!kIsWeb) return originalUrl;
    final encoded = Uri.encodeComponent(originalUrl);
    return 'https://api.allorigins.win/raw?url=$encoded';
  }

  Future<List<Article>> fetchTopHeadlines({String country = 'us', String? category}) async {
    var url = "$BASE_URL/top-headlines?country=$country&apiKey=$_apiKey";
    if (category != null && category.isNotEmpty) {
      url += '&category=${Uri.encodeComponent(category)}';
    }
    final finalUrl = _wrapWithProxyIfNeeded(url);
    return _fetchArticlesFromUrl(finalUrl, originalUrl: url);
  }

  Future<List<Article>> searchArticles(String query) async {
    final url = "$BASE_URL/everything?q=${Uri.encodeComponent(query)}&sortBy=publishedAt&apiKey=$_apiKey";
    final finalUrl = _wrapWithProxyIfNeeded(url);
    return _fetchArticlesFromUrl(finalUrl, originalUrl: url);
  }

  Future<List<Article>> _fetchArticlesFromUrl(String url, {String? originalUrl}) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      print('NEWSAPI: GET ${originalUrl ?? url} -> ${response.statusCode}');
      final bodyPreview = response.body.length > 800 ? '${response.body.substring(0, 800)}...[truncated]' : response.body;
      print('NEWSAPI BODY PREVIEW: $bodyPreview');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = json.decode(response.body);
        if (jsonBody['status'] == 'ok') {
          final List articlesJson = jsonBody['articles'] as List;
          return articlesJson.map((e) => Article.fromJson(e)).toList();
        } else {
          throw Exception('API returned status: ${jsonBody['status']}');
        }
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      print('NEWSAPI ERROR: $e');
      rethrow;
    }
  }
}
