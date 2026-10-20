import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import 'folder_stats.dart';

/// Last eCourse2 answer for each request, kept on the device so screens can
/// show it at once while asking again. Answers are stored per account (the
/// token's hash), so another sign-in never sees them, and are removed on
/// sign-out. Kept in Application Support, outside Documents and Files.
class ResponseCache {
  /// [dir] replaces the app's support folder, for tests.
  ResponseCache(String token, {Directory? dir})
    : _account = _hash(token),
      _dir = dir; // ignore: prefer_initializing_formals, a public name reads better

  final String _account;
  final Directory? _dir;

  static String _hash(String s) => sha1.convert(utf8.encode(s)).toString();

  static Future<Directory> _root() async =>
      Directory('${(await getApplicationSupportDirectory()).path}/ecourse');

  /// One file per function and parameters; the token is not part of it.
  static String keyOf(String function, Map<String, String> params) {
    final sorted = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return _hash('$function ${jsonEncode(sorted)}');
  }

  Future<File> _file(String key) async {
    final dir = Directory('${(_dir ?? await _root()).path}/$_account');
    await dir.create(recursive: true);
    return File('${dir.path}/$key.json');
  }

  /// The stored answer, or null when this request was never answered.
  Future<Object?> read(String key) async {
    final file = await _file(key);
    if (!await file.exists()) return null;
    return jsonDecode(await file.readAsString());
  }

  Future<void> write(String key, Object? value) async =>
      (await _file(key)).writeAsString(jsonEncode(value));

  /// Every account's answers, for the settings page.
  static Future<FolderStats> stats() async => folderStats(await _root());

  /// Removes every account's answers.
  static Future<void> clear() async {
    final root = await _root();
    if (await root.exists()) await root.delete(recursive: true);
  }
}
