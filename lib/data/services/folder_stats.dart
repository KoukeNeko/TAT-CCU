import 'dart:io';

/// One saved file, named without its extension, for the settings pages.
typedef SavedFile = ({String name, int bytes, DateTime modified});

typedef FolderStats = ({int files, int bytes, DateTime? latest});

/// Every file under [dir]; empty when the folder does not exist.
Future<List<SavedFile>> savedFiles(Directory dir) async {
  if (!await dir.exists()) return [];
  return [
    await for (final entity in dir.list(recursive: true))
      if (entity is File)
        await entity.stat().then(
          (stat) => (
            name: entity.uri.pathSegments.last.replaceFirst(
              RegExp(r'\.json$'),
              '',
            ),
            bytes: stat.size,
            modified: stat.modified,
          ),
        ),
  ];
}

FolderStats summarize(Iterable<SavedFile> files) => (
  files: files.length,
  bytes: files.fold(0, (sum, f) => sum + f.bytes),
  latest: files
      .map((f) => f.modified)
      .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a),
);
