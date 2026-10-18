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

typedef ModuleFile = ({String name, int size, String url, DateTime modified});

/// [id] is the course module id used in links; [instance] is the id of the
/// assignment, quiz, etc. behind it. [due] is the assignment due date or the
/// quiz close date.
typedef Module = ({
  int id,
  int instance,
  String name,
  String type,
  String? url,
  List<ModuleFile> files,
  DateTime? due,
});
typedef Section = ({String name, List<Module> modules});
typedef Post = ({String subject, String author, DateTime time, String body});
typedef GradeLine = ({String name, String grade, String percent});

/// A calendar entry. [cmid] links assignment and quiz events to their
/// module page.
typedef CalendarEvent = ({
  String name,
  String label,
  String course,
  int courseId,
  int? cmid,
  DateTime time,
  String? url,
});

/// One student's view of an assignment. [grade] is null until graded.
typedef Assignment = ({
  String intro,
  List<ModuleFile> attachments,
  DateTime? opens,
  DateTime? due,
  DateTime? submittedAt,
  List<ModuleFile> submission,
  String? grade,
});

/// [finished] is the latest finished attempt; [grade] is null until graded.
typedef Quiz = ({
  String intro,
  DateTime? opens,
  DateTime? closes,
  DateTime? finished,
  String? grade,
});

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
    assignCourseColors(list);
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

  /// Every event in [month], from the same feed as eCourse2's month view.
  Future<List<CalendarEvent>> monthEvents(DateTime month) async {
    final r = await _client.call('core_calendar_get_calendar_monthly_view', {
      'year': month.year,
      'month': month.month,
    }) as Map;
    return [
      for (final w in r['weeks'] as List)
        for (final d in w['days'] as List)
          for (final e in d['events'] as List)
            (
              // `name` carries Moodle's suffix such as 在最近到期; the label
              // below says the same in fewer words.
              name: multilang('${e['activityname'] ?? e['name']}'),
              label: _eventLabel(
                '${e['modulename'] ?? ''}',
                '${e['eventtype']}',
              ),
              course: multilang('${e['course']?['fullname'] ?? ''}'),
              courseId: (e['course']?['id'] as num?)?.toInt() ?? 0,
              // Only assignments and quizzes have an in-app page.
              cmid: e['modulename'] == 'assign' || e['modulename'] == 'quiz'
                  ? int.tryParse(
                      Uri.tryParse('${e['url']}')?.queryParameters['id'] ?? '',
                    )
                  : null,
              time: _ts(e['timestart']),
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
          // Moodle's untranslated default name for the course-wide section.
          name: s['section'] == 0 && s['name'] == 'General'
              ? '一般'
              : multilang('${s['name']}'),
          modules: [
            for (final m in s['modules'] as List)
              if (m['modname'] != 'label')
                (
                  id: (m['id'] as num).toInt(),
                  instance: (m['instance'] as num?)?.toInt() ?? 0,
                  name: multilang('${m['name']}'),
                  type: '${m['modname']}',
                  url: m['url'] as String?,
                  files: [
                    for (final f in m['contents'] as List? ?? const [])
                      if (f['type'] == 'file') _file(f as Map),
                  ],
                  due: [
                    for (final d in m['dates'] as List? ?? const [])
                      if (d['dataid'] == 'duedate' ||
                          d['dataid'] == 'timeclose')
                        _ts(d['timestamp']),
                  ].firstOrNull,
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

  Future<Assignment> assignment(int courseId, int instance) async {
    final (list, status) = await (
      _client.call('mod_assign_get_assignments', {
        'courseids': [courseId],
      }),
      _currentUserId().then(
        (user) => _client.call('mod_assign_get_submission_status', {
          'assignid': instance,
          'userid': user,
        }),
      ),
    ).wait;
    final a = [
      for (final c in (list as Map)['courses'] as List)
        for (final a in c['assignments'] as List)
          if (a['id'] == instance) a,
    ].first;
    final submission = (status as Map)['lastattempt']?['submission'] as Map?;
    final submitted = submission?['status'] == 'submitted';
    final grade = status['feedback']?['gradefordisplay'] as String?;
    return (
      intro: _plain('${a['intro'] ?? ''}'),
      attachments: [
        for (final f in a['introattachments'] as List? ?? const [])
          _file(f as Map),
      ],
      opens: _date(a['allowsubmissionsfromdate']),
      due: _date(a['duedate']),
      submittedAt: submitted ? _date(submission!['timemodified']) : null,
      submission: [
        for (final p in submission?['plugins'] as List? ?? const [])
          for (final area in p['fileareas'] as List? ?? const [])
            for (final f in area['files'] as List? ?? const []) _file(f as Map),
      ],
      // `100.00&nbsp;/&nbsp;100.00`: keep the score, the page shows the max.
      grade: grade == null ? null : _plain(grade).split('/').first.trim(),
    );
  }

  Future<Quiz> quiz(int courseId, int instance) async {
    final (list, attempts, best) = await (
      _client.call('mod_quiz_get_quizzes_by_courses', {
        'courseids': [courseId],
      }),
      _client.call('mod_quiz_get_user_attempts', {
        'quizid': instance,
        'status': 'finished',
      }),
      _client.call('mod_quiz_get_user_best_grade', {'quizid': instance}),
    ).wait;
    final q = [
      for (final q in (list as Map)['quizzes'] as List)
        if (q['id'] == instance) q,
    ].first;
    final finished = [
      for (final a in (attempts as Map)['attempts'] as List)
        _date(a['timefinish']),
    ].nonNulls.toList()..sort();
    final grade = (best as Map)['hasgrade'] == true
        ? (best['grade'] as num)
        : null;
    return (
      intro: _plain('${q['intro'] ?? ''}'),
      opens: _date(q['timeopen']),
      closes: _date(q['timeclose']),
      finished: finished.lastOrNull,
      grade: grade == null
          ? null
          : grade % 1 == 0
          ? '${grade.toInt()}'
          : grade.toStringAsFixed(2),
    );
  }

  /// Files under `webservice/pluginfile.php` need the token to download.
  String fileUrl(String url) {
    final uri = Uri.parse(url);
    return uri
        .replace(
          queryParameters: {...uri.queryParameters, 'token': _client.token},
        )
        .toString();
  }

  /// Needs the real user id: without it Moodle asks for every user's grades,
  /// which students may not view (`nopermissions`).
  Future<List<GradeLine>> gradeItems(int courseId) async {
    final r = await _client.call('gradereport_user_get_grade_items', {
      'courseid': courseId,
      'userid': await _currentUserId(),
    }) as Map;
    final users = r['usergrades'] as List;
    if (users.isEmpty) return [];
    return [
      for (final i in users.first['gradeitems'] as List)
        // Course totals live in gradeOverview; categories carry no name.
        if (i['itemtype'] == 'mod' || i['itemtype'] == 'manual')
          (
            name: multilang('${i['itemname'] ?? ''}'),
            // Passing grades arrive as a check icon before the number; the
            // number alone already says it.
            grade: _plain('${i['gradeformatted'] ?? ''}'),
            percent: _plain('${i['percentageformatted'] ?? ''}'),
          ),
    ];
  }
}

String _eventLabel(String module, String type) {
  final what = switch (module) {
    'assign' => '作業',
    'quiz' => '測驗',
    '' => switch (type) {
      'course' => '課程事件',
      'user' => '個人事件',
      'site' => '全校事件',
      _ => '事件',
    },
    _ => '活動',
  };
  final when = switch (type) {
    'due' => '到期',
    'close' => '關閉',
    'open' => '開放',
    _ => '',
  };
  return '$what$when';
}

/// Moodle uses 0 for "not set".
DateTime? _date(Object? s) => (s as num? ?? 0) == 0 ? null : _ts(s);

ModuleFile _file(Map f) => (
  name: '${f['filename']}',
  size: (f['filesize'] as num?)?.toInt() ?? 0,
  url: '${f['fileurl']}',
  modified: _ts(f['timemodified']),
);

/// Moodle's multilang filter output, e.g.
/// `<span lang="zh_tw" class="multilang">出缺席</span><span lang="en" …>`;
/// keeps the Traditional Chinese text, or the plain text without spans.
String multilang(String html) =>
    RegExp(r'<span lang="zh_tw" class="multilang">(.*?)</span>')
        .firstMatch(html)
        ?.group(1) ??
    _plain(html);

/// Moodle returns HTML bodies; the list views only need plain text.
String _plain(String html) => html
    .replaceAll(RegExp(r'<br\s*/?>|</p>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();
