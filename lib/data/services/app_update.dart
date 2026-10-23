/// The newest release, for the version card in 設定: iOS asks the App Store,
/// which is the only place it can update from; the other platforms ask
/// GitHub, where every release lands first.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// [notes] are the release's own lines; [url] is where to update.
typedef AppRelease = ({
  String version,
  List<String> notes,
  Uri url,
  String source,
});

const _appStoreId = '6825362775';
const _playUrl =
    'https://play.google.com/store/apps/details?id=io.github.koukeneko.tat_ccu';

/// Null when the store lists no release yet.
Future<AppRelease?> latestRelease({http.Client? client}) async {
  final get = client?.get ?? http.get;
  if (Platform.isIOS) {
    final r = await get(
      Uri.parse('https://itunes.apple.com/lookup?id=$_appStoreId&country=tw'),
    ).timeout(const Duration(seconds: 15));
    _check(r, 'App Store');
    final results = (jsonDecode(utf8.decode(r.bodyBytes)) as Map)['results'];
    if (results is! List || results.isEmpty) return null;
    final app = results.first as Map;
    return (
      version: '${app['version']}',
      notes: releaseLines('${app['releaseNotes'] ?? ''}'),
      url: Uri.parse('${app['trackViewUrl']}'),
      source: 'App Store',
    );
  }
  final r = await get(
    Uri.parse('https://api.github.com/repos/KoukeNeko/TAT-CCU/releases/latest'),
    headers: {'Accept': 'application/vnd.github+json'},
  ).timeout(const Duration(seconds: 15));
  _check(r, 'GitHub');
  final release = jsonDecode(utf8.decode(r.bodyBytes)) as Map;
  return (
    version: '${release['tag_name']}'.replaceFirst(RegExp('^v'), ''),
    notes: releaseLines('${release['body'] ?? ''}'),
    url: Uri.parse(Platform.isAndroid ? _playUrl : '${release['html_url']}'),
    source: 'GitHub',
  );
}

void _check(http.Response r, String source) {
  if (r.statusCode != 200) {
    throw http.ClientException('$source release: ${r.statusCode}');
  }
}

/// The notes' items: Markdown headings and blank lines dropped.
List<String> releaseLines(String text) => [
  for (final line in text.split('\n'))
    if (line.trim() case final l when l.isNotEmpty && !l.startsWith('#')) l,
];

/// Whether [a] is a later `x.y.z` than [b]; parts missing count as 0.
bool isNewer(String a, String b) {
  List<int> parts(String v) => [
    for (final p in v.split('+').first.split('.')) int.tryParse(p) ?? 0,
  ];
  final x = parts(a), y = parts(b);
  for (var i = 0; i < 3; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d > 0;
  }
  return false;
}
