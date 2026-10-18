import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/domain/models/course.dart';
import 'package:tat_ccu/domain/models/timetable.dart';
import 'package:tat_ccu/ui/courses/course_detail_screen.dart';

void main() {
  const course = Course(
    id: 1,
    shortName: '115_1_0000000_01',
    fullName: 'Test',
    sessions: [
      ClassSession(weekday: 2, periods: ['C'], start: 610, end: 660),
    ],
  );

  test('next class later today, tomorrow, and next week', () {
    // 2026-10-20 is a Tuesday.
    expect(nextClassLabel(course, DateTime(2026, 10, 20, 9)), '今天 10:10');
    expect(nextClassLabel(course, DateTime(2026, 10, 19, 12)), '明天 10:10');
    expect(nextClassLabel(course, DateTime(2026, 10, 20, 12)), '週二 10:10');
  });

  test('no sessions means no next class', () {
    const empty = Course(id: 2, shortName: 'x_y', fullName: 'E');
    expect(nextClassLabel(empty, DateTime(2026, 10, 20)), isNull);
  });
}
