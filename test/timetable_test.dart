import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/domain/models/timetable.dart';

void main() {
  // Expected times come from real CCU courses shown in the EM3 timetable.
  test('lettered periods are 75 minutes', () {
    final s = parseSchedule('週二 C,D').single;
    expect(s.weekday, 2);
    expect(s.start, 10 * 60 + 15);
    expect(s.end, 13 * 60);
  });

  test('numbered periods are 50 minutes on the hour plus ten', () {
    final s = parseSchedule('週一 8,9').single;
    expect(s.weekday, 1);
    expect(s.start, 14 * 60 + 10);
    expect(s.end, 16 * 60);
  });

  test('several days and unknown tokens', () {
    final s = parseSchedule('週二 E,F 週四 Z 週五 3');
    expect(s.map((x) => x.weekday), [2, 5]);
    expect(s.first.end, 16 * 60);
  });

  test('empty value gives no sessions', () {
    expect(parseSchedule(''), isEmpty);
  });

  // An empty code between commas is an unknown code: its day is skipped,
  // and the other days still parse, instead of the course failing.
  test('an empty period code skips its day only', () {
    final s = parseSchedule('週二 C, 週四 D');
    expect(s.map((x) => x.weekday), [4]);
  });
}
