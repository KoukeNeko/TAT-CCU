import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'response_cache.dart';

/// Raised when eCourse2 answers with a Moodle exception instead of data.
class MoodleException implements Exception {
  MoodleException(this.errorCode, this.message);

  final String errorCode;
  final String message;

  /// The token expired or was revoked; the user has to sign in again.
  bool get needsSignIn => errorCode == 'invalidtoken';

  /// eCourse2 is in Moodle's maintenance mode, which refuses every student
  /// sign-in and call until it ends.
  bool get isMaintenance => errorCode == 'sitemaintenance';

  @override
  String toString() => 'MoodleException($errorCode): $message';
}

/// Calls Moodle web service functions over REST.
///
/// eCourse2 sits behind an F5 load balancer with one backend that holds
/// every request for 10 s; a connection that lands there stays there
/// (research_notes/…/ecourse2_latency_probe.md). So the client keeps the F5
/// cookie of a backend that answered quickly and sends it on every request,
/// and a request that stalls is sent again on a fresh connection.
class MoodleClient {
  /// eCourse2 answers within a few seconds; past this the request is stuck.
  static const _timeout = Duration(seconds: 30);

  /// Stalled attempts before the last one, which waits the full [_timeout].
  static const _switches = 2;

  MoodleClient({
    required this.siteUrl,
    required this.token,
    http.Client Function()? newHttpClient,
    this.cache,
    this.stallAfter = const Duration(seconds: 4),
  }) : _newHttpClient = newHttpClient ?? http.Client.new {
    _http = _newHttpClient();
  }

  final Uri siteUrl;
  final String token;
  final http.Client Function() _newHttpClient;
  late http.Client _http;

  /// The fast backend's `f5_persisten` value, once one has answered.
  String? _backend;

  /// Healthy answers come well within this; the slow backend takes 10 s.
  final Duration stallAfter;

  /// Every answer is saved here, for [offline] to read back.
  final ResponseCache? cache;

  /// A client that only answers from [cache], for showing the last data
  /// before the network answers.
  MoodleClient offline() => _OfflineMoodleClient(this);

  /// After the sign-in expired: [offline] still reads [cache], while every
  /// request fails as signed out, so screens show what was saved and say
  /// why it does not refresh.
  factory MoodleClient.savedOnly({
    required Uri siteUrl,
    required ResponseCache cache,
  }) = _SavedOnlyMoodleClient;

  /// [once]: a write. It goes out a single time with the full timeout, since
  /// a stalled or dropped request may still have reached eCourse2 and
  /// sending it again could post twice.
  Future<http.Response> _post(
    Uri url,
    Map<String, String> body, {
    bool once = false,
  }) async {
    var resent = false;
    for (var attempt = 0; ; attempt++) {
      final client = _http;
      final last = once || attempt == _switches;
      final watch = Stopwatch()..start();
      try {
        final response = await client
            .post(
              url,
              headers: {
                if (_backend case final backend?)
                  'cookie': 'f5_persisten=$backend',
              },
              body: body,
            )
            .timeout(last ? _timeout : stallAfter);
        if (watch.elapsed < stallAfter) {
          final set = response.headers['set-cookie'] ?? '';
          _backend =
              RegExp(r'f5_persisten=([^;,\s]+)').firstMatch(set)?[1] ??
              _backend;
        }
        return response;
      } on TimeoutException {
        if (last) rethrow;
        _leave(client);
      } on http.ClientException {
        // A pooled keep-alive connection can be dead without the client
        // knowing, most often after the app was suspended or the phone
        // switched networks, or [_leave] closed it under this request.
        // Sending again opens a fresh one; a write ([once]) is last, so it
        // is never sent again.
        if (last || resent) rethrow;
        resent = true;
      }
    }
  }

  /// Drops the stalled backend: forgets its cookie and closes its
  /// connections, so the next attempt is balanced afresh.
  void _leave(http.Client stalled) {
    if (!identical(stalled, _http)) return; // Another request already left.
    _backend = null;
    _http = _newHttpClient();
    stalled.close();
  }

  Future<dynamic> call(
    String function, [
    Map<String, Object?> params = const {},
  ]) async {
    final decoded = await _request(function, params);
    await cache?.write(
      ResponseCache.keyOf(function, flattenParams(params)),
      decoded,
    );
    return decoded;
  }

  /// Calls a function that changes something on eCourse2: sent once and
  /// never saved for [offline].
  Future<dynamic> send(
    String function, [
    Map<String, Object?> params = const {},
  ]) => _request(function, params, once: true);

  Future<dynamic> _request(
    String function,
    Map<String, Object?> params, {
    bool once = false,
  }) async {
    final body = {
      'wstoken': token,
      'wsfunction': function,
      'moodlewsrestformat': 'json',
      ...flattenParams(params),
    };
    final response = await _post(
      siteUrl.resolve('webservice/rest/server.php'),
      body,
      once: once,
    );
    if (response.statusCode != 200) {
      throw MoodleException('http${response.statusCode}', function);
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map && decoded['exception'] != null) {
      throw MoodleException('${decoded['errorcode']}', '${decoded['message']}');
    }
    return decoded;
  }
}

/// Thrown by an [MoodleClient.offline] client for a request never answered.
class CacheMiss implements Exception {
  const CacheMiss();
}

class _OfflineMoodleClient extends MoodleClient {
  _OfflineMoodleClient(MoodleClient online)
    : super(
        siteUrl: online.siteUrl,
        token: online.token,
        cache: online.cache,
        // Never sends a request; skips opening a real client.
        newHttpClient: () => _NoHttp(),
      );

  @override
  Future<dynamic> call(
    String function, [
    Map<String, Object?> params = const {},
  ]) async {
    final saved = await cache?.read(
      ResponseCache.keyOf(function, flattenParams(params)),
    );
    if (saved == null) throw const CacheMiss();
    return saved;
  }
}

class _SavedOnlyMoodleClient extends MoodleClient {
  _SavedOnlyMoodleClient({required super.siteUrl, required ResponseCache cache})
    : super(token: '', cache: cache, newHttpClient: () => _NoHttp());

  @override
  Future<dynamic> call(
    String function, [
    Map<String, Object?> params = const {},
  ]) async => throw MoodleException('invalidtoken', function);

  @override
  Future<dynamic> send(
    String function, [
    Map<String, Object?> params = const {},
  ]) async => throw MoodleException('invalidtoken', function);
}

/// Moodle REST expects nested values as `key[0][field]=value` form fields.
Map<String, String> flattenParams(Map<String, Object?> params) {
  final out = <String, String>{};
  void add(String key, Object? value) {
    switch (value) {
      case null:
        return;
      case Map():
        value.forEach((k, v) => add('$key[$k]', v));
      case List():
        for (var i = 0; i < value.length; i++) {
          add('$key[$i]', value[i]);
        }
      case bool():
        out[key] = value ? '1' : '0';
      default:
        out[key] = '$value';
    }
  }

  params.forEach(add);
  return out;
}

class _NoHttp extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw StateError('offline');
}
