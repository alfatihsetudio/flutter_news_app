import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _base = "http://api.wafe.co.id/api";

  Future<String> login({required String email, required String password}) async {
    final url = Uri.parse("$_base/login");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final body = jsonDecode(res.body);

    if (res.statusCode != 200 || body["meta"]["status"] == false) {
      throw ApiException(body["meta"]["message"] ?? "Login gagal");
    }

    return body["access_token"];
  }

  Future<String> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$_base/register");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );

    final body = jsonDecode(res.body);

    if (res.statusCode != 201 || body["meta"]["status"] == false) {
      throw ApiException(body["meta"]["message"] ?? "Registrasi gagal");
    }

    return body["access_token"];
  }

  Future<Map<String, dynamic>> profile(String token) async {
    final url = Uri.parse("$_base/profile");

    final res = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    final body = jsonDecode(res.body);

    if (res.statusCode != 200 || body["meta"]["status"] == false) {
      throw ApiException(body["meta"]["message"] ?? "Gagal ambil profil");
    }

    return Map<String, dynamic>.from(body["data"]);
  }

  Future<void> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse("$_base/update-password");

    final res = await http.post(
      url,
      headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
      body: jsonEncode({
        "current_password": oldPassword,
        "new_password": newPassword,
        "new_password_confirmation": newPassword,
      }),
    );

    final body = jsonDecode(res.body);

    if (res.statusCode != 200 || body["meta"]["status"] == false) {
      throw ApiException(body["meta"]["message"] ?? "Gagal ubah password");
    }
  }

  Future<void> logout(String token) async {
    final url = Uri.parse("$_base/logout");
    await http.get(url, headers: {"Authorization": "Bearer $token"});
  }
}
