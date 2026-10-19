import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../services/moodle_client.dart';
import '../services/response_cache.dart';

/// eCourse2 site root; the mobile launch flow hashes it exactly as written.
const eCourse2Url = 'https://ecourse2.ccu.edu.tw';

/// Custom scheme Moodle redirects to with the token.
const callbackScheme = 'tatccu';

/// Owns the eCourse2 web service token. Only the token is stored; the app
/// never sees the SSO password. Independent of the CAS session, see
/// docs/登入狀態設計.md.
class EcourseAuthRepository extends ChangeNotifier {
  EcourseAuthRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'ecourse2_token';

  final FlutterSecureStorage _storage;
  String? _token;

  String? get token => _token;
  bool get isSignedIn => _token != null;

  MoodleClient client() => MoodleClient(
    siteUrl: Uri.parse('$eCourse2Url/'),
    token: _token ?? '',
    cache: _token == null ? null : ResponseCache(_token!),
  );

  Future<void> load() async {
    _token = await _storage.read(key: _tokenKey);
    notifyListeners();
  }

  /// Runs the `admin/tool/mobile/launch.php` flow in the system browser; the
  /// user signs in to CAS there.
  Future<void> signIn() async {
    final random = Random.secure();
    final passport = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final launch = Uri.parse('$eCourse2Url/admin/tool/mobile/launch.php')
        .replace(
          queryParameters: {
            'service': 'moodle_mobile_app',
            'passport': passport,
            'urlscheme': callbackScheme,
            'oauthsso': '1',
            'confirmed': '1',
          },
        );
    final callback = await FlutterWebAuth2.authenticate(
      url: launch.toString(),
      callbackUrlScheme: callbackScheme,
    );
    await signInWithCallback(callback, passport);
  }

  /// Completes the launch flow with the `<scheme>://token=...` callback.
  Future<void> signInWithCallback(String callback, String passport) async {
    final token = parseLaunchCallback(callback, passport);
    await _storage.write(key: _tokenKey, value: token);
    _token = token;
    notifyListeners();
  }

  /// Asks eCourse2 whether the token still works; returns the account name.
  /// An expired token signs the user out.
  Future<String> verify() async {
    try {
      final info = await client().call('core_webservice_get_site_info') as Map;
      return '${info['fullname']}';
    } on MoodleException catch (e) {
      if (e.needsSignIn) await signOut();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _storage.delete(key: _tokenKey);
    await ResponseCache.clear();
    _token = null;
    notifyListeners();
  }
}

/// Decodes `base64(md5(site + passport) ::: token [::: privatetoken])` and
/// checks the signature so a forged callback cannot plant a token.
///
/// Takes the raw callback string: parsing it as a [Uri] would treat
/// `token=...` as the host and lowercase the base64 payload.
String parseLaunchCallback(String raw, String passport) {
  final start = raw.indexOf('token=');
  if (start < 0) throw const FormatException('No token in callback');
  final parts = utf8
      .decode(base64.decode(raw.substring(start + 'token='.length)))
      .split(':::');
  final expected = md5.convert(utf8.encode('$eCourse2Url$passport')).toString();
  if (parts.length < 2 || parts[0] != expected) {
    throw const FormatException('Callback signature does not match');
  }
  return parts[1];
}
