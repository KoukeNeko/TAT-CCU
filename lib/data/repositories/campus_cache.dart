import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

typedef CachedPage = ({Map<String, dynamic> json, DateTime savedAt});

/// The last data a campus page read, kept on the device so the page opens
/// at once and offline; it reads the school again only when pulled down.
/// Kept in Application Support, which iOS does not back up to iCloud
/// documents or show in Files.
class CampusCache {
  const CampusCache._();

  static Future<File> _file(String key) async {
    final dir = Directory(
      '${(await getApplicationSupportDirectory()).path}/campus',
    );
    await dir.create(recursive: true);
    return File('${dir.path}/$key.json');
  }

  static Future<CachedPage?> read(String key) async {
    final file = await _file(key);
    if (!await file.exists()) return null;
    final stored =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return (
      json: stored['json'] as Map<String, dynamic>,
      savedAt: DateTime.fromMillisecondsSinceEpoch(stored['savedAt'] as int),
    );
  }

  static Future<DateTime> write(String key, Map<String, dynamic> json) async {
    final now = DateTime.now();
    await (await _file(key)).writeAsString(
      jsonEncode({'savedAt': now.millisecondsSinceEpoch, 'json': json}),
    );
    return now;
  }
}
