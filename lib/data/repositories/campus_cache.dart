import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../services/folder_stats.dart';

typedef CachedPage = ({Map<String, dynamic> json, DateTime savedAt});

/// The last data a campus page read, kept on the device so the page opens
/// at once and offline; it reads the school again only when pulled down.
/// Kept in Application Support, which iOS does not back up to iCloud
/// documents or show in Files.
class CampusCache {
  const CampusCache._();

  /// The demo account's pages, kept in a folder of their own.
  static var demo = false;

  static Future<Directory> _dir() async => Directory(
    '${(await getApplicationSupportDirectory()).path}/${demo ? 'campus-demo' : 'campus'}',
  );

  static Future<File> _file(String key) async {
    final dir = await _dir();
    await dir.create(recursive: true);
    return File('${dir.path}/$key.json');
  }

  /// The current account's pages, for the settings page.
  static Future<FolderStats> stats() async => folderStats(await _dir());

  /// Every page's last read, for signing out.
  static Future<void> clear() async {
    final dir = await _dir();
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// Null when nothing was saved, or the file is damaged (a write cut
  /// short), so the page reads the school again instead of never loading.
  static Future<CachedPage?> read(String key) async {
    final file = await _file(key);
    if (!await file.exists()) return null;
    try {
      final stored =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return (
        json: stored['json'] as Map<String, dynamic>,
        savedAt: DateTime.fromMillisecondsSinceEpoch(stored['savedAt'] as int),
      );
    } on Object catch (e) {
      debugPrint('campus cache $key unreadable: $e');
      return null;
    }
  }

  static Future<DateTime> write(String key, Map<String, dynamic> json) async {
    final now = DateTime.now();
    await (await _file(key)).writeAsString(
      jsonEncode({'savedAt': now.millisecondsSinceEpoch, 'json': json}),
    );
    return now;
  }
}
