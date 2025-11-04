import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _kToken = 'auth_token';
  final _s = const FlutterSecureStorage();

  Future<void> save(String token) => _s.write(key: _kToken, value: token);
  Future<String?> read() => _s.read(key: _kToken);
  Future<void> clear() => _s.delete(key: _kToken);
}
