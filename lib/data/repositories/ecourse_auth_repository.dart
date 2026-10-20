import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../services/campus_cookies.dart';
import '../services/demo_data.dart';
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
  static const _demoKey = 'demo_account';
  static const _campusOnlyKey = 'campus_only';

  final FlutterSecureStorage _storage;
  final bool _migrate;
  String? _token;
  var _signedOutByUser = false;
  var _demo = false;
  var _campusOnly = false;

  String? get token => _token;

  /// Signed in to eCourse2, or using the demo account.
  bool get isSignedIn => _demo || _token != null;

  /// The demo account: every screen shows made-up data, nothing is read
  /// from or sent to the school, and its saved pages are kept apart. The
  /// real sign-in stays as it was, to switch back to.
  bool get isDemo => _demo;

  /// The app opens: signed in to eCourse2, using the demo, or using only
  /// the campus systems, which sign in through the portal on their own
  /// (for when eCourse2 is down for maintenance).
  bool get canEnter => isSignedIn || _campusOnly;

  /// Opens the app without eCourse2, or goes back to signing in to it.
  Future<void> setCampusOnly(bool on) async {
    if (on) {
      await _storage.write(key: _campusOnlyKey, value: '1');
    } else {
      await _storage.delete(key: _campusOnlyKey);
    }
    _campusOnly = on;
    notifyListeners();
  }

  /// The user pressed 登出: no signing in by itself with a saved password
  /// until the user signs in again.
  bool get signedOutByUser => _signedOutByUser;

  MoodleClient client() => _demo
      ? DemoMoodleClient()
      : MoodleClient(
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
    _demo = await _storage.read(key: _demoKey) != null;
    _campusOnly = await _storage.read(key: _campusOnlyKey) != null;
    CampusCache.demo = _demo;
    notifyListeners();
  }

  /// Switches to the demo account, or back to the real one, which may be
  /// signed out.
  Future<void> setDemo(bool on) async {
    if (on) {
      await _storage.write(key: _demoKey, value: '1');
    } else {
      await _storage.delete(key: _demoKey);
      // The demo's pages start fresh the next time.
      await CampusCache.clear();
    }
    _demo = on;
    CampusCache.demo = on;
    notifyListeners();
  }

  /// Whether eCourse2 is in maintenance mode, from its public mobile
  /// settings (no account needed). Signing in cannot work then: Moodle
  /// refuses students, and launch.php only shows the maintenance page.
  /// False when the settings cannot be read, so sign-in is tried as usual.
  static Future<bool> siteInMaintenance({http.Client? httpClient}) async {
    final client = httpClient ?? http.Client();
    try {
      final response = await client
          .post(
            Uri.parse(
              '$eCourse2Url/lib/ajax/service-nologin.php'
              '?info=tool_mobile_get_public_config',
            ),
            body: jsonEncode([
              {
                'index': 0,
                'methodname': 'tool_mobile_get_public_config',
                'args': {},
              },
            ]),
          )
          .timeout(const Duration(seconds: 10));
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return json is List &&
          json.first is Map &&
          json.first['data']?['maintenanceenabled'] == 1;
    } on Exception catch (e) {
      debugPrint('eCourse2 maintenance check: $e');
      return false;
    } finally {
      if (httpClient == null) client.close();
    }
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
    await _storage.delete(key: _campusOnlyKey);
    _campusOnly = false;
    _token = token;
    _signedOutByUser = false;
    notifyListeners();
  }

  /// Asks eCourse2 whether the token still works; returns the account name.
  /// An expired token signs the user out.
  Future<String> verify() async {
    if (_demo) return demoName;
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
    // Signing out of the demo leaves the real account as it was.
    if (_demo) return setDemo(false);
    await _storage.delete(key: _tokenKey);
    await ResponseCache.clear();
    if (byUser) {
      await _storage.write(key: _signedOutKey, value: '1');
      await _storage.delete(key: _campusOnlyKey);
      _campusOnly = false;
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
