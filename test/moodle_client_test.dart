import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tat_ccu/data/repositories/ecourse_auth_repository.dart';
import 'package:tat_ccu/data/services/moodle_client.dart';

void main() {
  test('flattens nested params the way Moodle REST expects', () {
    expect(
      flattenParams({
        'courseids': [3, 5],
        'options': {
          'ids': [7],
        },
        'flag': true,
        'skip': null,
      }),
      {
        'courseids[0]': '3',
        'courseids[1]': '5',
        'options[ids][0]': '7',
        'flag': '1',
      },
    );
  });

  test('turns a Moodle exception body into MoodleException', () async {
    final client = MoodleClient(
      siteUrl: Uri.parse('https://example.test/'),
      token: 't',
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'exception': 'x',
            'errorcode': 'invalidtoken',
            'message': 'm',
          }),
          200,
        ),
      ),
    );
    expect(
      client.call('core_webservice_get_site_info'),
      throwsA(
        isA<MoodleException>().having(
          (e) => e.needsSignIn,
          'needsSignIn',
          true,
        ),
      ),
    );
  });

  group('launch callback', () {
    const passport = 'abc123';
    String callback(String signature) =>
        'tatccu://token=${base64.encode(utf8.encode('$signature:::TOKEN:::PRIVATE'))}';
    final valid = md5.convert(utf8.encode('$eCourse2Url$passport')).toString();

    test('returns the token when the signature matches', () {
      expect(parseLaunchCallback(callback(valid), passport), 'TOKEN');
    });

    test('rejects a forged signature', () {
      expect(
        () => parseLaunchCallback(callback('forged'), passport),
        throwsFormatException,
      );
    });
  });

  test('retries once when a reused connection was already closed', () async {
    var calls = 0;
    final client = MoodleClient(
      siteUrl: Uri.parse('https://example.test/'),
      token: 't',
      httpClient: MockClient((_) async {
        calls++;
        if (calls == 1) {
          throw http.ClientException(
            'Connection closed before full header was received',
          );
        }
        return http.Response(jsonEncode({'ok': true}), 200);
      }),
    );
    expect(await client.call('core_webservice_get_site_info'), {'ok': true});
    expect(calls, 2);
  });

  test('gives up after the retry fails too', () async {
    var calls = 0;
    final client = MoodleClient(
      siteUrl: Uri.parse('https://example.test/'),
      token: 't',
      httpClient: MockClient((_) async {
        calls++;
        throw http.ClientException('Connection reset by peer');
      }),
    );
    await expectLater(
      client.call('core_webservice_get_site_info'),
      throwsA(isA<http.ClientException>()),
    );
    expect(calls, 2);
  });
}
