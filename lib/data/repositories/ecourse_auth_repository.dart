import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/campus_cookies.dart';
import '../services/moodle_client.dart';
import '../services/response_cache.dart';
import 'campus_cache.dart';

/// eCourse2 site root; the mobile launch flow hashes it exactly as written.
const eCourse2Url = 'https://ecourse2.ccu.edu.tw';

/// Custom scheme Moodle redirects to with the token.
const callbackScheme = 'tatccu';

/// Owns the eCourse2 web service token. Independent of the CAS session, see
/// docs/登入狀態設計.md.
class EcourseAuthRepository extends ChangeNotifier {
  EcourseAuthRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? _keychain,
      _migrate = storage == null;

  /// Readable after the first unlock, so the background check for new
  /// notices works while the phone is locked.
  static const _keychain = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _tokenKey = 'ecourse2_token';
  static const _signedOutKey = 'signed_out_by_user';

  final FlutterSecureStorage _storage;
  final bool _migrate;
  String? _token;
  var _signedOutByUser = false;

  String? get token => _token;
  bool get isSignedIn => _token != null;

  /// The user pressed 登出: no signing in by itself with a saved password
  /// until the user signs in again.
  bool get signedOutByUser => _signedOutByUser;

  MoodleClient client() => MoodleClient(
    siteUrl: Uri.parse('$eCourse2Url/'),
    token: _token ?? '',
    cache: _token == null ? null : ResponseCache(_token!),
  );

  Future<void> load() async {
    if (_migrate) {
      // Saved before with access only while unlocked: move them over.
      const legacy = FlutterSecureStorage();
      for (final key in [_tokenKey, _signedOutKey]) {
        if (await legacy.read(key: key) case final value?) {
          await _storage.write(key: key, value: value);
          await legacy.delete(key: key);
        }
      }
    }
    _token = await _storage.read(key: _tokenKey);
    _signedOutByUser = await _storage.read(key: _signedOutKey) != null;
    notifyListeners();
  }

  /// A new `admin/tool/mobile/launch.php` sign-in: the page signs in to
  /// CAS and ends by redirecting to `tatccu://token=...` for this passport.
  ({Uri url, String passport}) newLaunch() {
    final random = Random.secure();
    final passport = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final url = Uri.parse('$eCourse2Url/admin/tool/mobile/launch.php').replace(
      queryParameters: {
        'service': 'moodle_mobile_app',
        'passport': passport,
        'urlscheme': callbackScheme,
        'oauthsso': '1',
        'confirmed': '1',
      },
    );
    return (url: url, passport: passport);
  }

  /// Completes the launch flow with the `<scheme>://token=...` callback.
  Future<void> signInWithCallback(String callback, String passport) async {
    final token = parseLaunchCallback(callback, passport);
    await _storage.write(key: _tokenKey, value: token);
    await _storage.delete(key: _signedOutKey);
    _token = token;
    _signedOutByUser = false;
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

  /// [byUser] also ends the CAS and campus sessions, which otherwise sign
  /// the next sign-in straight back in, and drops their cached pages.
  Future<void> signOut({bool byUser = false}) async {
    await _storage.delete(key: _tokenKey);
    await ResponseCache.clear();
    if (byUser) {
      await _storage.write(key: _signedOutKey, value: '1');
      await (CampusCookies.clear(), CampusCache.clear()).wait;
      _signedOutByUser = true;
    }
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
