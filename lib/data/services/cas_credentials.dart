import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef CasLogin = ({String username, String password});

/// The CAS username and password, kept only when the user asks to sign in
/// automatically. Stays on this device: not synced to iCloud Keychain.
class CasCredentials {
  const CasCredentials._();

  static const _key = 'cas_credentials';
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<CasLogin?> read() async {
    final stored = await _storage.read(key: _key);
    if (stored == null) return null;
    final json = jsonDecode(stored) as Map<String, dynamic>;
    return (
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }

  static Future<void> save(CasLogin login) => _storage.write(
    key: _key,
    value: jsonEncode({'username': login.username, 'password': login.password}),
  );

  static Future<void> delete() => _storage.delete(key: _key);
}
