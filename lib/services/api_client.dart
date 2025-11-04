import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient I = ApiClient._();

  static const _baseUrl = 'http://api.wafe.co.id/api';
  final _storage = const FlutterSecureStorage();

  late final Dio dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 25),
    receiveTimeout: const Duration(seconds: 25),
    sendTimeout: const Duration(seconds: 25),
    headers: {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    },
  ))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'token');
        if (token != null && token.isNotEmpty) {
          options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));

  // Helpers
  Future<Response<T>> getJson<T>(String path, {Map<String, dynamic>? query}) =>
      dio.get<T>(path, queryParameters: query);

  Future<Response<T>> postJson<T>(String path, Map<String, dynamic> body) =>
      dio.post<T>(path, data: body);
}
