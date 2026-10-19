/// eCourse2 pages without a web service the app may call: mod_attendance
/// (its Moodle App handler records attendance as a side effect and lists
/// only the next day) and the custom mod_absenceform. Read through a signed-in
/// WebView instead (research_notes/…/ecourse2_modules_probe.md).
library;

import 'dart:convert';

const ecourseHost = 'ecourse2.ccu.edu.tw';

/// Lands on the login page when signed out, which [ecourseScript] handles.
const ecourseEntry = 'https://$ecourseHost/my/';

/// Wraps [body] (JS with `parse(path)` and `post(json)` in scope) so that
/// it signs in through CCU 單一登入 first unless a student is signed in; CAS
/// then returns here and the script runs again. Only a signed-in student's
/// page has the logout link: a guest session is not signed out either.
String ecourseScript(String body) =>
    '''
(async () => {
  if (!document.querySelector('a[href*="/login/logout.php"]')) {
    const sso = document.querySelector('a[href*="auth/oauth2/login.php"]');
    if (sso) {
      location.href = sso.href;
    } else if (!location.pathname.startsWith('/login/')) {
      location.href = '/login/index.php';
    } else {
      throw new Error('eCourse2 sign-in link not found');
    }
    return;
  }
  const parse = async path => new DOMParser().parseFromString(
    await (await fetch(path, { credentials: 'same-origin' })).text(), 'text/html');
  const post = json => Campus.postMessage(JSON.stringify(json));
  const cells = tr => [...tr.cells].map(c => c.textContent.replace(/\\s+/g, ' ').trim());
  $body
})().catch(e => Campus.postMessage(JSON.stringify({ error: String(e) })));
''';

/// Every session of the course (`view=5`) and the summary rows.
String readAttendance(int cmid) => ecourseScript('''
  const doc = await parse('/mod/attendance/view.php?id=$cmid&view=5');
  // Every attendance page has the summary; without it this is an error or
  // sign-in page, not an empty course.
  if (!doc.querySelector('table.attlist')) throw new Error(doc.title);
  post({
    kind: 'attendance',
    rows: [...doc.querySelectorAll('table.attwidth tbody tr')].map(cells),
    summary: [...doc.querySelectorAll('table.attlist tr')].map(cells),
  });
''');

/// The student's own requests and the course name the form fills in.
String readAbsences(int cmid) => ecourseScript('''
  const [self, form] = await Promise.all([
    parse('/mod/absenceform/viewself.php?id=$cmid'),
    parse('/mod/absenceform/view.php?id=$cmid'),
  ]);
  const table = self.querySelector('table');
  post({
    kind: 'absences',
    head: table ? [...table.querySelectorAll('thead th')].map(th => th.textContent.trim()) : [],
    rows: table ? [...table.querySelectorAll('tbody tr')].map(cells).filter(r => r.length > 1) : [],
    course: form.querySelector('[name=coursename]')?.value || '',
  });
''');

/// Fills the site's form with [request] and posts it, with the page's own
/// sesskey. Answers `ok` unless the form comes back with an error.
String submitAbsence(int cmid, AbsenceRequest request) {
  final fields = jsonEncode({
    'absencedate[day]': '${request.date.day}',
    'absencedate[month]': '${request.date.month}',
    'absencedate[year]': '${request.date.year}',
    'absenceclassification': '${request.type}',
    'courseclassification': request.online ? '1' : '0',
    'absenceRemark': request.remark,
    'submitbutton': '送出',
  });
  return ecourseScript('''
  const page = await parse('/mod/absenceform/view.php?id=$cmid');
  const form = page.querySelector('form[action*="absenceform.php"]');
  if (!form) throw new Error('absence form not found');
  const body = new URLSearchParams();
  for (const input of form.querySelectorAll('input[type=hidden], input[name=coursename]')) {
    body.set(input.name, input.value);
  }
  for (const [k, v] of Object.entries($fields)) body.set(k, v);
  const r = await fetch(new URL(form.getAttribute('action'), location.origin + '/mod/absenceform/'),
    { method: 'POST', body, credentials: 'same-origin' });
  const done = new DOMParser().parseFromString(await r.text(), 'text/html');
  const error = [...done.querySelectorAll('.invalid-feedback, .error')]
    .map(e => e.textContent.trim()).find(Boolean);
  post({ kind: 'submitted', ok: r.ok && !error, error: error || (r.ok ? null : 'HTTP ' + r.status) });
''');
}

/// [type] is the site's radio value: 事假 0, 病假 1, 公假 2, 喪假 3, 娩假 4.
typedef AbsenceRequest = ({
  DateTime date,
  int type,
  bool online,
  String remark,
});

/// [status] and [points] are empty until the session is taken; the site
/// shows `?` for them.
typedef AttendanceSession = ({
  DateTime? date,
  String time,
  String description,
  String status,
  String points,
  String remark,
});

typedef Attendance = ({
  List<AttendanceSession> sessions,
  String? rate,
  String? points,
  String? taken,
});

/// `出席Present` → `出席`: the site joins the Chinese and English names.
String _chinese(String s) => RegExp(r'^[㐀-鿿]+').stringMatch(s) ?? s;

Attendance attendanceOf(Map<String, dynamic> json) {
  final sessions = <AttendanceSession>[
    for (final row in (json['rows'] as List? ?? const []).whereType<List>())
      if (row.length >= 5)
        () {
          final when = '${row[0]}';
          final m = RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日').firstMatch(when);
          return (
            date: m == null
                ? null
                : DateTime(
                    int.parse(m[1]!),
                    int.parse(m[2]!),
                    int.parse(m[3]!),
                  ),
            // `2026年10月20日 (週二) 10:15AM - 12點PM` → the part after `)`.
            time: when.contains(')') ? when.split(')').last.trim() : when,
            description: '${row[1]}',
            status: '${row[2]}' == '?' ? '' : _chinese('${row[2]}'),
            points: '${row[3]}'.startsWith('?') ? '' : '${row[3]}',
            remark: '${row[4]}',
          );
        }(),
  ];
  // The first three rows are this course's taken sessions: count, points
  // and percentage; later rows repeat them for every session.
  final values = [
    for (final row in (json['summary'] as List? ?? const []).whereType<List>())
      if (row.length >= 2) '${row[1]}',
  ];
  String? first(RegExp pattern) =>
      values.take(3).where(pattern.hasMatch).firstOrNull;
  return (
    sessions: sessions,
    taken: first(RegExp(r'^\d+$')),
    points: first(RegExp(r'^[\d.]+\s*/\s*[\d.]+$')),
    rate: first(RegExp(r'%$')),
  );
}
