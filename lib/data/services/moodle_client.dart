import 'dart:convert';

import 'package:http/http.dart' as http;

/// Raised when eCourse2 answers with a Moodle exception instead of data.
class MoodleException implements Exception {
  MoodleException(this.errorCode, this.message);

  final String errorCode;
  final String message;

  /// The token expired or was revoked; the user has to sign in again.
  bool get needsSignIn => errorCode == 'invalidtoken';

  @override
  String toString() => 'MoodleException($errorCode): $message';
}

/// Calls Moodle web service functions over REST.
class MoodleClient {
  MoodleClient({
    required this.siteUrl,
    required this.token,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final Uri siteUrl;
  final String token;
  final http.Client _http;

  Future<dynamic> call(
    String function, [
    Map<String, Object?> params = const {},
  ]) async {
    final response = await _http.post(
      siteUrl.resolve('webservice/rest/server.php'),
      body: {
        'wstoken': token,
        'wsfunction': function,
        'moodlewsrestformat': 'json',
        ...flattenParams(params),
      },
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
