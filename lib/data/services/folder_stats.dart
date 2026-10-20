import 'dart:io';

/// How much a cache folder holds, for the settings page.
typedef FolderStats = ({int files, int bytes, DateTime? latest});

/// Every file under [dir]; empty when the folder does not exist.
Future<FolderStats> folderStats(Directory dir) async {
  var files = 0, bytes = 0;
  DateTime? latest;
  if (await dir.exists()) {
    await for (final entity in dir.list(recursive: true)) {
      if (entity is! File) continue;
      final stat = await entity.stat();
      files++;
      bytes += stat.size;
      if (latest == null || stat.modified.isAfter(latest)) {
        latest = stat.modified;
      }
    }
  }
  return (files: files, bytes: bytes, latest: latest);
}
