import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, dynamic>? errors;
  ApiException(this.message, {this.statusCode, this.errors});
  @override
  String toString() => message;
}

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  static const _httpsBase = 'https://api.wafe.co.id/api';
  static const _httpBase  = 'http://api.wafe.co.id/api'; // fallback utk Android

  Uri _u(String base, String path) => Uri.parse('$base$path');

  Map<String, String> _headers({String? token}) => {
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
        if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
      };

  Future<Map<String, dynamic>> _decode(http.Response r) async {
    try {
      return json.decode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Gagal membaca respon server', statusCode: r.statusCode);
    }
  }

  Never _throwFrom(Map<String, dynamic> body, int code) {
    String msg = body['meta']?['message']?.toString() ??
        'Terjadi kesalahan ($code)';
    final errs = body['errors'];
    if (errs is Map && errs.isNotEmpty) {
      final list = <String>[];
      for (final e in errs.entries.take(2)) {
        final v = e.value;
        if (v is List && v.isNotEmpty) list.add(v.first.toString());
        if (v is String) list.add(v);
      }
      if (list.isNotEmpty) msg = '$msg: ${list.join(", ")}';
    }
    throw ApiException(msg, statusCode: code,
        errors: errs is Map ? errs.cast<String, dynamic>() : null);
  }

  /// Kirim request, coba HTTPS dulu → jika gagal (Handshake/Client) **di Android** fallback ke HTTP.
  Future<http.Response> _post(String path, Map<String, dynamic> body,
      {String? token}) async {
    // Web: jangan paksa HTTP (CORS tetap masalah). Biarkan error jelas.
    final bases = kIsWeb ? const [_httpsBase] : const [_httpsBase, _httpBase];

    Object? lastErr;
    for (final base in bases) {
      try {
        final r = await http
            .post(_u(base, path), headers: _headers(token: token), body: json.encode(body))
            .timeout(const Duration(seconds: 25));
        return r;
      } on HandshakeException catch (e) {
        lastErr = e;
        continue;
      } on SocketException catch (e) {
        lastErr = e;
        continue;
      } on http.ClientException catch (e) {
        lastErr = e;
        continue;
      }
    }
    throw ApiException('Gagal menghubungi server: ${lastErr ?? "unknown"}');
  }

  Future<http.Response> _get(String path, {String? token}) async {
    final bases = kIsWeb ? const [_httpsBase] : const [_httpsBase, _httpBase];
    Object? lastErr;
    for (final base in bases) {
      try {
        final r = await http
            .get(_u(base, path), headers: _headers(token: token))
            .timeout(const Duration(seconds: 25));
        return r;
      } on HandshakeException catch (e) {
        lastErr = e; continue;
      } on SocketException catch (e) {
        lastErr = e; continue;
      } on http.ClientException catch (e) {
        lastErr = e; continue;
      }
    }
    throw ApiException('Gagal menghubungi server: ${lastErr ?? "unknown"}');
  }

  // ---------- Endpoints ----------
  Future<String> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? address,
  }) async {
    final r = await _post('/register', {
      'name': name,
      'email': email,
      'password': password,
      if (phone?.isNotEmpty == true) 'phone': phone,
      if (address?.isNotEmpty == true) 'address': address,
    });

    final body = await _decode(r);
    if (r.statusCode == 201 || r.statusCode == 200) {
      final token = (body['access_token'] ?? '').toString();
      if (token.isEmpty) {
        throw ApiException('Registrasi ok, tapi token kosong', statusCode: r.statusCode);
      }
      return token;
    }
    _throwFrom(body, r.statusCode);
  }

  Future<String> login({required String email, required String password}) async {
    final r = await _post('/login', {'email': email, 'password': password});
    final body = await _decode(r);
    if (r.statusCode == 200) {
      final token = (body['access_token'] ?? '').toString();
      if (token.isEmpty) {
        throw ApiException('Login ok, tapi token kosong', statusCode: r.statusCode);
      }
      return token;
    }
    _throwFrom(body, r.statusCode);
  }

  Future<Map<String, dynamic>> profile(String token) async {
    final r = await _get('/profile', token: token);
    final body = await _decode(r);
    if (r.statusCode == 200 && body['data'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(body['data']);
    }
    _throwFrom(body, r.statusCode);
  }

  Future<void> logout(String token) async {
    final r = await _get('/logout', token: token);
    if (r.statusCode == 200) return;
    final body = await _decode(r);
    _throwFrom(body, r.statusCode);
  }

  Future<void> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    final r = await _post('/update-password', {
      'current_password': oldPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPassword,
    }, token: token);

    if (r.statusCode == 200) return;
    final body = await _decode(r);
    _throwFrom(body, r.statusCode);
  }
}
