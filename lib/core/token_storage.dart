import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistance du jeton JWT — stockage sécurisé (Keychain iOS / EncryptedSharedPreferences
/// Android), jamais en clair sur le disque.
class TokenStorage {
  TokenStorage._();
  static const _storage = FlutterSecureStorage();
  static const _key = 'allowaw_auth_token';

  static Future<void> save(String token) => _storage.write(key: _key, value: token);
  static Future<String?> read() => _storage.read(key: _key);
  static Future<void> clear() => _storage.delete(key: _key);
}
