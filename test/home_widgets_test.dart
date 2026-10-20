import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/data/services/school_calendar.dart';
import 'package:tat_ccu/domain/models/course.dart';
import 'package:tat_ccu/domain/models/timetable.dart';
import 'package:tat_ccu/l10n/app_localizations.dart';
import 'package:tat_ccu/ui/home_widgets/home_widgets.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadSchoolCalendar();
  final zh = lookupAppLocalizations(const Locale('zh'));
  // 2026-10-20 is a Tuesday, during a 10:15–12:05 class.
  final now = DateTime(2026, 10, 20, 10, 42);
  const courses = [
    Course(
      id: 1,
      shortName: '115_1_0000001_01',
      fullName: 'Operating Systems作業系統',
      room: '工學院二館 321',
      sessions: [
        ClassSession(weekday: 2, periods: ['C'], start: 615, end: 725),
      ],
    ),
    Course(
      id: 2,
      shortName: '115_1_0000002_01',
      fullName: 'Deep Learning深度學習導論',
      room: '創新大樓 109',
      sessions: [
        ClassSession(weekday: 2, periods: ['8'], start: 790, end: 840),
        ClassSession(weekday: 4, periods: ['2'], start: 490, end: 540),
      ],
    ),
  ];
  final due = [
    (
      name: '作業三',
      course: 'Operating Systems作業系統',
      courseId: 1,
      due: DateTime(2026, 10, 20, 23, 59),
      module: 'assign',
      url: null,
    ),
  ];
  final data = widgetData(
    courses: courses,
    due: due,
    now: now,
    l10n: zh,
    signedIn: true,
    courseColor: (_) => const Color(0xFFCEC0E8),
  );
  final frames = data['frames'] as List<Map<String, Object?>>;
  Map<String, Object?> at(DateTime t) =>
      frames.lastWhere((f) => (f['at'] as int) <= t.millisecondsSinceEpoch);
  Map cls(DateTime t) => at(t)['class'] as Map;

  test('a frame for each class boundary, deadline and midnight', () {
    final times = [
      for (final f in frames)
        DateTime.fromMillisecondsSinceEpoch(f['at'] as int),
    ];
    expect(times.first, now);
    expect(
      times,
      containsAll([
        DateTime(2026, 10, 20, 12, 5),
        DateTime(2026, 10, 20, 13, 10),
        DateTime(2026, 10, 20, 23, 59),
        DateTime(2026, 10, 21),
        DateTime(2026, 10, 22, 8, 10),
      ]),
    );
    expect(times.last.isBefore(now.add(const Duration(days: 7))), isTrue);
  });

  test('in class, then the next class, then the next day', () {
    expect(cls(now), containsPair('label', '上課中'));
    expect(cls(now), containsPair('until', '到 12:05'));
    expect(
      cls(now)['end'],
      DateTime(2026, 10, 20, 12, 5).millisecondsSinceEpoch,
    );

    final noon = DateTime(2026, 10, 20, 12, 30);
    expect(cls(noon), containsPair('label', '下一堂'));
    expect(cls(noon), containsPair('name', '深度學習導論'));
    expect(cls(noon), containsPair('time', '13:10'));
    expect(cls(noon)['end'], isNull);

    final evening = DateTime(2026, 10, 20, 18);
    expect(cls(evening), containsPair('label', '今天的課結束了'));
    expect(cls(evening), containsPair('sub', '週四第一堂'));
    expect(cls(evening), containsPair('time', '8:10'));

    final wednesday = DateTime(2026, 10, 21, 9);
    expect(cls(wednesday), containsPair('label', '今天沒有課'));
    expect(cls(wednesday), containsPair('sub', '明天第一堂'));
  });

  test("today's remaining classes and deadlines", () {
    final day = at(now)['day'] as Map;
    expect(day['headline'], '今天還有兩堂課');
    expect([for (final r in day['rows'] as List) r['now']], [true, false]);

    final dueNow = at(now)['due'] as Map;
    expect(dueNow['count'], 1);
    expect((dueNow['rows'] as List).single['when'], '今天 23:59');
    final dueLater = at(DateTime(2026, 10, 21))['due'] as Map;
    expect(dueLater['count'], 0);
  });

  test('countdown to the next school date', () {
    final countdown = at(now)['countdown'] as Map;
    expect(countdown['title'], '臺灣光復節補假');
    expect(countdown['value'], '6');
    expect(countdown['week'], '第 7 週・共 18 週');
  });
}
