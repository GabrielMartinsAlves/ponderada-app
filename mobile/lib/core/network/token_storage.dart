import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Armazenamento seguro dos tokens de sessão (access/refresh).
class TokenStorage {
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  final FlutterSecureStorage _s;
  TokenStorage([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();

  Future<String?> get accessToken => _s.read(key: _kAccess);
  Future<String?> get refreshToken => _s.read(key: _kRefresh);

  Future<void> save({required String accessToken, required String refreshToken}) async {
    await _s.write(key: _kAccess, value: accessToken);
    await _s.write(key: _kRefresh, value: refreshToken);
  }

  Future<void> clear() async {
    await _s.delete(key: _kAccess);
    await _s.delete(key: _kRefresh);
  }

  Future<bool> hasSession() async => (await accessToken) != null;
}
