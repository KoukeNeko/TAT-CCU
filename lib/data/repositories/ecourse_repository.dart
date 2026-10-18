import '../../domain/models/course.dart';
import '../services/moodle_client.dart';

/// Something due soon, from `core_calendar_get_action_events_by_timesort`.
typedef DueItem = ({
  String name,
  String course,
  int courseId,
  DateTime due,
  String module,
  String? url,
});

typedef NoticeItem = ({
  String subject,
  String text,
  DateTime time,
  bool read,
  String? url,
});

typedef MailItem = ({
  String subject,
  String sender,
  String course,
  DateTime time,
  bool unread,
});

typedef Module = ({String name, String type, String? url});
typedef Section = ({String name, List<Module> modules});
typedef Post = ({String subject, String author, DateTime time, String body});
typedef GradeLine = ({String name, String grade, String percent});

DateTime _ts(Object? s) =>
    DateTime.fromMillisecondsSinceEpoch(((s as num?) ?? 0).toInt() * 1000);

/// Read-only access to eCourse2. Every function here was verified with a
/// student token; see CCU 研究報告彙整/eCourse2 功能分類.md.
class EcourseRepository {
  EcourseRepository(this._client);

  final MoodleClient _client;
  List<Course>? _courses;
  int? _userId;

  Future<int> _currentUserId() async => _userId ??=
      ((await _client.call('core_webservice_get_site_info') as Map)['userid']
              as num)
          .toInt();

  /// Enrolled courses with timetable custom fields, newest semester first.
  /// Cached for the session; pass [refresh] to refetch.
  Future<List<Course>> courses({bool refresh = false}) async {
    if (_courses != null && !refresh) return _courses!;
    final info = await _client.call('core_webservice_get_site_info') as Map;
    final enrolled = await _client.call('core_enrol_get_users_courses', {
      'userid': info['userid'],
    }) as List;
    if (enrolled.isEmpty) return _courses = [];
    final detail = await _client.call('core_course_get_courses_by_field', {
      'field': 'ids',
      'value': enrolled.map((c) => c['id']).join(','),
    }) as Map;
    final list = [
      for (final c in detail['courses'] as List)
        Course.fromMoodle(c as Map<String, dynamic>),
    ]..sort((a, b) => b.shortName.compareTo(a.shortName));
    return _courses = list;
  }

  /// Courses of the newest semester, which is what the timetable shows.
  Future<List<Course>> currentCourses({bool refresh = false}) async {
    final all = await courses(refresh: refresh);
    if (all.isEmpty) return all;
    final latest = all.first.semester;
    return all.where((c) => c.semester == latest).toList();
  }

  Future<List<DueItem>> dueSoon({int days = 14}) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final r = await _client.call(
      'core_calendar_get_action_events_by_timesort',
      {'timesortfrom': now, 'timesortto': now + days * 86400, 'limitnum': 50},
    ) as Map;
    return [
      for (final e in r['events'] as List)
        (
          name: '${e['activityname'] ?? e['name']}',
          course: '${e['course']?['fullname'] ?? ''}',
          courseId: (e['course']?['id'] as num?)?.toInt() ?? 0,
          due: _ts(e['timesort']),
          module: '${e['modulename'] ?? ''}',
          url: e['url'] as String?,
        ),
    ];
  }

  /// Needs the real user id: CCU answers `accessdenied` to `useridto: 0`.
  Future<int> unreadNotices() async => (await _client.call(
    'message_popup_get_unread_popup_notification_count',
    {'useridto': await _currentUserId()},
  ) as num).toInt();

  Future<List<NoticeItem>> notices() async {
    final r = await _client.call('message_popup_get_popup_notifications', {
      'useridto': 0,
      'limit': 40,
    }) as Map;
    return [
      for (final n in r['notifications'] as List)
        (
          subject: '${n['subject']}',
          text: '${n['smallmessage'] ?? ''}',
          time: _ts(n['timecreated']),
          read: n['read'] == true,
          url: n['contexturl'] as String?,
        ),
    ];
  }

  Future<int> unreadMail() async =>
      (await _client.call('local_mail_get_unread_count') as num).toInt();

  /// Inbox listing only; opening a message would mark it read on eCourse2.
  Future<List<MailItem>> inbox() async {
    final r = await _client.call('local_mail_get_index', {
      'type': 'inbox',
      'itemid': 0,
      'offset': 0,
      'limit': 40,
    }) as Map;
    return [
      for (final m in r['messages'] as List)
        (
          subject: '${m['subject']}',
          sender: '${m['sender']?['fullname'] ?? ''}',
          course: '${m['course']?['shortname'] ?? ''}',
          time: _ts(m['time']),
          unread: m['unread'] == true,
        ),
    ];
  }

  Future<List<Section>> contents(int courseId) async {
    final r = await _client.call('core_course_get_contents', {
      'courseid': courseId,
    }) as List;
    return [
      for (final s in r)
        (
          name: '${s['name']}',
          modules: [
            for (final m in s['modules'] as List)
              if (m['modname'] != 'label')
                (
                  name: '${m['name']}',
                  type: '${m['modname']}',
                  url: m['url'] as String?,
                ),
          ],
        ),
    ].where((s) => s.modules.isNotEmpty).toList();
  }

  Future<List<Post>> announcements(int courseId) async {
    final forums = await _client.call('mod_forum_get_forums_by_courses', {
      'courseids': [courseId],
    }) as List;
    final news = forums.where((f) => f['type'] == 'news').toList();
    if (news.isEmpty) return [];
    final r = await _client.call('mod_forum_get_forum_discussions', {
      'forumid': news.first['id'],
    }) as Map;
    return [
      for (final d in r['discussions'] as List)
        (
          subject: '${d['subject'] ?? d['name']}',
          author: '${d['userfullname'] ?? ''}',
          time: _ts(d['timemodified'] ?? d['created']),
          body: _plain('${d['message'] ?? ''}'),
        ),
    ];
  }

  /// courseId → overall grade text, as eCourse2 formats it.
  Future<Map<int, String>> gradeOverview() async {
    final r =
        await _client.call('gradereport_overview_get_course_grades') as Map;
    return {
      for (final g in r['grades'] as List)
        (g['courseid'] as num).toInt(): '${g['grade'] ?? '-'}',
    };
  }

  Future<List<GradeLine>> gradeItems(int courseId) async {
    final r = await _client.call('gradereport_user_get_grade_items', {
      'courseid': courseId,
    }) as Map;
    final users = r['usergrades'] as List;
    if (users.isEmpty) return [];
    return [
      for (final i in users.first['gradeitems'] as List)
        if (i['itemtype'] != 'course')
          (
            name: '${i['itemname'] ?? ''}',
            grade: '${i['gradeformatted'] ?? '-'}',
            percent: '${i['percentageformatted'] ?? ''}',
          ),
    ];
  }
}

/// Moodle returns HTML bodies; the list views only need plain text.
String _plain(String html) => html
    .replaceAll(RegExp(r'<br\s*/?>|</p>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();
