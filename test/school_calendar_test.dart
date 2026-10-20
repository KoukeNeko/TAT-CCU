import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/data/services/school_calendar.dart';

void main() {
  test('the calendar asset parses, dates in order', () {
    final calendar = parseSchoolCalendar(
      File(schoolCalendarAsset).readAsStringSync(),
    );
    expect(calendar.terms, hasLength(2));
    final starts = [for (final d in calendar.dates) d.start];
    expect(starts, [...starts]..sort());
    expect(calendar.dates.first, (
      start: DateTime(2026, 9, 7),
      end: null,
      title: '第 1 學期上課開始',
    ));
  });

  test('days, ranges, semesters and comments', () {
    final calendar = parseSchoolCalendar('''
# 116 學年度
學期 2027-09-13~2028-01-14
2027-11-08~2027-11-14 期中考試週  # 第 9 週
2027-09-13 第 1 學期上課開始
''');
    expect(calendar.terms.single, (
      start: DateTime(2027, 9, 13),
      end: DateTime(2028, 1, 14),
    ));
    expect(calendar.dates, [
      (start: DateTime(2027, 9, 13), end: null, title: '第 1 學期上課開始'),
      (
        start: DateTime(2027, 11, 8),
        end: DateTime(2027, 11, 14),
        title: '期中考試週',
      ),
    ]);
  });

  test('rejects lines it cannot read', () {
    for (final line in [
      '2027/09/13 上課開始',
      '2027-09-13',
      '2027-11-14~2027-11-08 期中考試週',
      '學期 2027-09-13',
      '學期 2027-09-13~2028-01-14 上學期',
    ]) {
      expect(
        () => parseSchoolCalendar(line),
        throwsFormatException,
        reason: line,
      );
    }
  });
}
