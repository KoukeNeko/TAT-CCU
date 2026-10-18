import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the campus sign-in (portal, CAS and each system's session cookie)
/// across app launches. The cookies are session cookies, so iOS drops them
/// when the app ends; they are copied to the Keychain and put back into the
/// WebViews' store on the next launch. The server's own idle timeout still
/// applies, after which the systems ask to sign in again.
class CampusCookies {
  const CampusCookies._();

  static const _channel = MethodChannel('tatccu/campus_cookies');
  static const _key = 'campus_cookies';
  static const _storage = FlutterSecureStorage();

  static Future<void> save() async {
    try {
      final cookies = await _channel.invokeListMethod<Object?>('read');
      await _storage.write(key: _key, value: jsonEncode(cookies ?? const []));
    } on MissingPluginException {
      // Only iOS registers the channel.
    }
  }

  static Future<void> restore() async {
    final stored = await _storage.read(key: _key);
    if (stored == null) return;
    try {
      await _channel.invokeMethod<void>('write', jsonDecode(stored));
    } on MissingPluginException {
      // Only iOS registers the channel.
    }
  }
}
