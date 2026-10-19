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
        newHttpClient: () =>
            MockClient((_) async => http.Response(jsonEncode(count), 200)),
      ),
    );

    // Nothing saved yet: only the network answer.
    expect(await repo().watch((r) => r.unreadMail()).toList(), [3]);

    // A later visit: the saved 3 at once, then the new 5.
    count = 5;
    expect(await repo().watch((r) => r.unreadMail()).toList(), [3, 5]);
  });

  test('a saved site_info answers the user id without the network', () async {
    final dir = await Directory.systemTemp.createTemp('cache');
    addTearDown(() => dir.delete(recursive: true));
    final calls = <String>[];
    EcourseRepository repo() => EcourseRepository(
      MoodleClient(
        siteUrl: Uri.parse('https://example.test/'),
        token: 't',
        cache: ResponseCache('t', dir: dir),
        newHttpClient: () => MockClient((request) async {
          final function = request.bodyFields['wsfunction']!;
          calls.add(function);
          return http.Response(
            jsonEncode(
              function == 'core_webservice_get_site_info' ? {'userid': 7} : 2,
            ),
            200,
          );
        }),
      ),
    );

    // First launch asks eCourse2 who the user is.
    await repo().unreadNotices();
    expect(calls, contains('core_webservice_get_site_info'));

    // The next launch reuses the saved answer.
    calls.clear();
    expect(await repo().unreadNotices(), 2);
    expect(calls, ['message_popup_get_unread_popup_notification_count']);
  });

  test('prefetch saves what the timetable reads for each course', () async {
    final dir = await Directory.systemTemp.createTemp('cache');
    addTearDown(() => dir.delete(recursive: true));
    final client = MoodleClient(
      siteUrl: Uri.parse('https://example.test/'),
      token: 't',
      cache: ResponseCache('t', dir: dir),
      newHttpClient: () => MockClient((request) async {
        final answer = switch (request.bodyFields['wsfunction']) {
          'core_webservice_get_site_info' => {'userid': 7},
          'core_enrol_get_users_courses' => [
            {'id': 3},
          ],
          'core_course_get_courses_by_field' => {
            'courses': [
              {'id': 3, 'shortname': '115_1_1_01', 'fullname': 'c'},
            ],
          },
          'core_calendar_get_action_events_by_timesort' => {'events': []},
          'gradereport_overview_get_course_grades' => {'grades': []},
          'mod_forum_get_forums_by_courses' => [
            {'id': 9, 'type': 'news'},
          ],
          'mod_forum_get_forum_discussions' => {'discussions': []},
          _ => throw StateError('unexpected ${request.bodyFields}'),
        };
        return http.Response(jsonEncode(answer), 200);
      }),
    );
    await EcourseRepository(client).prefetch();

    // Answered from the saved files alone.
    final saved = EcourseRepository(client.offline());
    expect(await saved.announcements(3), isEmpty);
    expect(await saved.gradeOverview(), isEmpty);
  });
}
