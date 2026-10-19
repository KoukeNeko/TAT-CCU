import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tat_ccu/data/repositories/ecourse_repository.dart';
import 'package:tat_ccu/data/services/moodle_client.dart';
import 'package:tat_ccu/data/services/response_cache.dart';

void main() {
  test('shows the saved answer first, then the fresh one', () async {
    final dir = await Directory.systemTemp.createTemp('cache');
    addTearDown(() => dir.delete(recursive: true));
    var count = 3;
    EcourseRepository repo() => EcourseRepository(
      MoodleClient(
        siteUrl: Uri.parse('https://example.test/'),
        token: 't',
        cache: ResponseCache('t', dir: dir),
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(count), 200),
        ),
      ),
    );

    // Nothing saved yet: only the network answer.
    expect(await repo().watch((r) => r.unreadMail()).toList(), [3]);

    // A later visit: the saved 3 at once, then the new 5.
    count = 5;
    expect(await repo().watch((r) => r.unreadMail()).toList(), [3, 5]);
  });
}
