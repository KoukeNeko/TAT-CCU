import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/data/services/reminders.dart';
import 'package:tat_ccu/domain/models/course.dart';
import 'package:tat_ccu/domain/models/timetable.dart';
import 'package:tat_ccu/l10n/app_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  // As Reminders.init sets it: class times are Taiwan wall-clock times.
  tz.initializeTimeZones();
  final taipei = tz.getLocation('Asia/Taipei');
  tz.setLocalLocation(taipei);
  final zh = lookupAppLocalizations(const Locale('zh'));
  // 2026-10-20 is a Tuesday.
  final now = tz.TZDateTime(taipei, 2026, 10, 20, 9);
  const course = Course(
    id: 1,
    shortName: '115_1_0000000_01',
    fullName: 'Software Analysis軟體分析',
    room: '創新大樓 322',
    sessions: [
      ClassSession(weekday: 2, periods: ['C'], start: 615, end: 725),
    ],
  );
  final due = (
    name: '作業三',
    course: 'Software Analysis軟體分析',
    courseId: 1,
    due: tz.TZDateTime(taipei, 2026, 10, 20, 9, 30),
    module: 'assign',
    url: null,
  );

  test('deadlines and classes ahead of now, soonest first', () {
    final list = remindersFor(
      courses: [course],
      due: [due],
      now: now,
      dueOn: true,
      classOn: true,
      l10n: zh,
    );
    // Both reminders for a deadline 30 minutes away are already past.
    expect(list.first.at, tz.TZDateTime(taipei, 2026, 10, 20, 10, 5));
    expect(list.first.title, '軟體分析');
    expect(list.first.body, '10 分鐘後上課・創新大樓 322');
    // Tapping it opens the course.
    expect(list.first.payload, '/courses/1');
    // Only today's class: next Tuesday is a week out.
    expect(list, hasLength(1));
    expect(list.map((r) => r.id), [for (var i = 1; i <= list.length; i++) i]);
  });

  test('a past hour drops that reminder, the switches drop their kind', () {
    final later = due.due.add(const Duration(days: 2));
    final list = remindersFor(
      courses: [course],
      due: [
        (
          name: due.name,
          course: due.course,
          courseId: 1,
          due: later,
          module: 'assign',
          url: 'https://ecourse2.ccu.edu.tw/mod/assign/view.php?id=7',
        ),
      ],
      now: now,
      dueOn: true,
      classOn: false,
      l10n: zh,
    );
    expect(list.map((r) => r.at), [
      later.subtract(const Duration(hours: 24)),
      later.subtract(const Duration(hours: 1)),
    ]);
    expect(list.first.body, '24 小時後截止・軟體分析');
    // Tapping it opens the assignment.
    expect(
      list.first.payload,
      'https://ecourse2.ccu.edu.tw/mod/assign/view.php?id=7',
    );
  });

  // A device set to Tokyo still gets the 10:15 Taiwan class at 10:05 Taiwan
  // time, not ten minutes before 10:15 Tokyo time.
  test('class reminders follow Taiwan time on a device elsewhere', () {
    final tokyo = tz.TZDateTime(tz.getLocation('Asia/Tokyo'), 2026, 10, 20, 9);
    final list = remindersFor(
      courses: [course],
      due: const [],
      now: tokyo,
      dueOn: false,
      classOn: true,
      l10n: zh,
    );
    expect(
      list.first.at.isAtSameMomentAs(
        tz.TZDateTime(taipei, 2026, 10, 20, 10, 5),
      ),
      isTrue,
    );
  });
}
