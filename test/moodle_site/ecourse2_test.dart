// Runs the app's eCourse2 reads and writes against the local Moodle test
// site (tool/moodle-test). Skipped unless tool/moodle-test/setup.sh has
// written the fixture, so `flutter test` alone needs no Moodle.
//
//   tool/moodle-test/setup.sh && flutter test test/moodle_site
library;

import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart' show Element;
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:tat_ccu/data/repositories/ecourse_repository.dart';
import 'package:tat_ccu/data/services/ecourse_web.dart';
import 'package:tat_ccu/data/services/moodle_client.dart';
import 'package:tat_ccu/ui/courses/attendance_scan_screen.dart';

final _fixtureFile = File('tool/moodle-test/build/fixture.json');

void main() {
  if (!_fixtureFile.existsSync()) {
    test('eCourse2 test site', () {}, skip: 'run tool/moodle-test/setup.sh');
    return;
  }
  final fixture = jsonDecode(_fixtureFile.readAsStringSync()) as Map;
  final site = Uri.parse('${fixture['site']}/');
  late EcourseRepository repo;
  // Each run writes new posts and comments; names stay apart by the time.
  final stamp = DateTime.now().millisecondsSinceEpoch;

  setUpAll(() async {
    // The token the mobile launch flow would hand over after CAS.
    final r = await http.post(
      site.resolve('login/token.php'),
      body: {
        'username': fixture['username'],
        'password': fixture['password'],
        'service': 'moodle_mobile_app',
      },
    );
    final token = (jsonDecode(r.body) as Map)['token'] as String;
    repo = EcourseRepository(MoodleClient(siteUrl: site, token: token));
  });

  test('lists this semester\'s courses with their timetable fields', () async {
    final courses = await repo.currentCourses();
    expect(courses, hasLength(2));
    final course = courses.firstWhere((c) => c.id == fixture['courseId']);
    expect(course.room, '創新大樓322');
    expect(course.sessions, isNotEmpty);
    // Moodle's own name format; eCourse2 may join them differently.
    expect(course.teachers.single, allOf(contains('王'), contains('教授')));
  });

  test('reads course contents, deadlines and grades', () async {
    final courseId = fixture['courseId'] as int;
    final sections = await repo.contents(courseId);
    final types = {
      for (final s in sections)
        for (final m in s.modules) m.type,
    };
    expect(types, containsAll(['forum', 'assign', 'attendance']));

    final due = await repo.dueSoon(days: 7);
    expect(due.map((d) => d.name), contains('作業一：效能分析'));

    final grades = await repo.gradeItems(courseId);
    expect(grades.where((g) => g.name == '期中考').map((g) => g.grade), [
      startsWith('88'),
    ]);

    final events = await repo.monthEvents(clock.now());
    expect(events.map((e) => e.name), anyElement(contains('作業一')));
  });

  test('reads the announcements forum', () async {
    final news = await repo.announcements(fixture['courseId'] as int);
    expect(news.map((d) => d.subject), contains('期中考範圍'));
  });

  test('starts a discussion and replies in it', () async {
    final forumId = fixture['forumId'] as int;
    expect(await repo.canStartDiscussion(forumId), isTrue);

    // Text is sent as HTML; markup typed by the student stays text.
    final subject = '測試發問 $stamp';
    await repo.startDiscussion(forumId, subject, '第一題的 <b>輸入</b> 格式？');
    final discussions = await repo.discussions(forumId);
    final started = discussions.firstWhere((d) => d.subject == subject);
    expect(started.body, contains('<b>輸入</b>'));

    final posts = await repo.discussionPosts(started.id);
    await repo.replyToPost(posts.first.id, 'Re: $subject', '補充：\n第二行');
    final replies = await repo.discussionPosts(started.id);
    expect(replies, hasLength(2));
    expect(replies.last.parent, posts.first.id);
    expect(replies.last.body, contains('第二行'));
  });

  test('adds and deletes a submission comment', () async {
    final cmid = fixture['assignCmid'] as int;
    final submission = fixture['submissionId'] as int;
    final text = '已上傳修正版 $stamp';
    await repo.addSubmissionComment(cmid, submission, text);
    var thread = await repo.submissionComments(cmid, submission);
    expect(thread.canPost, isTrue);
    final mine = thread.comments.firstWhere((c) => c.text == text);
    expect(mine.mine, isTrue);

    await repo.deleteSubmissionComment(mine.id);
    thread = await repo.submissionComments(cmid, submission);
    expect(thread.comments.where((c) => c.id == mine.id), isEmpty);
  });

  test('marks mail read and unread', () async {
    final inbox = await repo.inbox();
    final mail = inbox.firstWhere((m) => m.subject == '期中考教室異動');
    expect(mail.sender, contains('王'));

    // Fetching a message leaves it unread on local_mail 1.x.
    final message = await repo.mailMessage(mail.id);
    expect(message.body, contains('創新大樓 110'));
    expect(
      (await repo.inbox()).firstWhere((m) => m.id == mail.id).unread,
      isTrue,
    );

    await repo.markMailRead(mail.id);
    expect(await repo.unreadMail(), 0);
    expect(
      (await repo.inbox()).firstWhere((m) => m.id == mail.id).unread,
      isFalse,
    );

    await repo.markMailUnread(mail.id);
    expect(await repo.unreadMail(), 1);
  });

  test('reads the sent box with its recipients', () async {
    // The seed's letter went from the teacher, the other account it creates.
    final r = await http.post(
      site.resolve('login/token.php'),
      body: {
        'username': 'teacher',
        'password': fixture['password'],
        'service': 'moodle_mobile_app',
      },
    );
    final teacher = EcourseRepository(
      MoodleClient(
        siteUrl: site,
        token: (jsonDecode(r.body) as Map)['token'] as String,
      ),
    );
    final mail = (await teacher.sent()).firstWhere(
      (m) => m.subject == '期中考教室異動',
    );
    expect(mail.to, contains('同學'));
    expect((await teacher.mailMessage(mail.id)).to, contains('同學'));
    // The student's inbox has it, not the student's sent box.
    expect(
      await repo.sent(),
      isNot(contains(predicate<MailItem>((m) => m.id == mail.id))),
    );
  });

  test('marks a notification read', () async {
    final notice = (await repo.notices()).firstWhere(
      (n) => n.subject == '作業一已評分',
    );
    if (notice.read) return markTestSkipped('already read in an earlier run');
    final before = await repo.unreadNotices();

    await repo.markNoticeRead(notice.id);
    expect(await repo.unreadNotices(), before - 1);
    expect(
      (await repo.notices()).firstWhere((n) => n.id == notice.id).read,
      isTrue,
    );
  });

  test('checks in through the attendance QR link', () async {
    final web = _WebSession(site);
    await web.signIn(
      fixture['username'] as String,
      fixture['password'] as String,
    );
    // What the app opens after scanning the classroom's code.
    final link = Uri.parse(fixture['attendanceUrl'] as String);
    expect(isAttendanceLink(link.replace(host: ecourseHost)), isTrue);
    await web.get(link);

    // The page readAttendance parses, with the same selectors.
    final page = html.parse(
      await web.get(
        site.resolve(
          'mod/attendance/view.php?id=${fixture['attendanceCmid']}&view=5',
        ),
      ),
    );
    List<String> cells(Element tr) => [
      for (final c in tr.children)
        c.text.replaceAll(RegExp(r'\s+'), ' ').trim(),
    ];
    expect(page.querySelector('table.attlist'), isNotNull);
    final attendance = attendanceOf({
      'rows': page
          .querySelectorAll('table.attwidth tbody tr')
          .map(cells)
          .toList(),
      'summary': page.querySelectorAll('table.attlist tr').map(cells).toList(),
    });
    expect(attendance.sessions, hasLength(1));
    final session = attendance.sessions.single;
    expect(session.date, isNotNull);
    expect(session.description, '第八週');
    expect(session.status, '出席');
  });
}

/// A signed-in browser session on the test site, as the campus WebView has
/// on eCourse2: one cookie, carried across redirects.
class _WebSession {
  _WebSession(this.site);

  final Uri site;
  final _client = http.Client();
  String? _cookie;

  Future<String> get(Uri url) async => (await _send('GET', url)).body;

  Future<http.Response> _send(
    String method,
    Uri url, [
    Map<String, String>? form,
  ]) async {
    for (var hops = 0; hops < 10; hops++) {
      final request = http.Request(method, url)..followRedirects = false;
      if (_cookie != null) request.headers['cookie'] = _cookie!;
      if (form != null) request.bodyFields = form;
      final response = await http.Response.fromStream(
        await _client.send(request),
      );
      final set = response.headers['set-cookie'];
      final session = set == null
          ? null
          : RegExp(r'MoodleSession=[^;]+').stringMatch(set);
      if (session != null) _cookie = session;
      final location = response.headers['location'];
      if (!response.isRedirect || location == null) return response;
      url = url.resolve(location);
      method = 'GET';
      form = null;
    }
    throw StateError('too many redirects from $url');
  }

  Future<void> signIn(String username, String password) async {
    final login = site.resolve('login/index.php');
    final form = html.parse(await get(login));
    final token = form
        .querySelector('input[name=logintoken]')!
        .attributes['value']!;
    final page = await _send('POST', login, {
      'username': username,
      'password': password,
      'logintoken': token,
    });
    if (!page.body.contains('/login/logout.php')) {
      throw StateError('test site sign-in failed');
    }
  }
}
