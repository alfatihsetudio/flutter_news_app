// lib/state/token_store.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _key = 'auth_token';

  static Future<void> save(String token) async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      const storage = FlutterSecureStorage();
      await storage.write(key: _key, value: token);
    } else {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_key, token);
    }
  }

  static Future<String?> read() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      const storage = FlutterSecureStorage();
      return storage.read(key: _key);
    } else {
      final sp = await SharedPreferences.getInstance();
      return sp.getString(_key);
    }
  }

  static Future<void> clear() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      const storage = FlutterSecureStorage();
      await storage.delete(key: _key);
    } else {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_key);
    }
  }
}
