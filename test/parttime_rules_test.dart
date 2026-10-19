import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/ui/more/parttime_data.dart';

HoursEntry entry(DateTime date, int start, int end) => (
  id: '$date$start',
  date: date,
  unit: '圖書館',
  start: start * 60,
  end: end * 60,
  work: '',
  state: HoursState.unconfirmed,
  batch: null,
);

void main() {
  // 2026-10-19 is a Monday.
  final monday = DateTime(2026, 10, 19);

  test('a week counts weekdays only, from its Monday', () {
    final entries = [
      entry(monday, 9, 12),
      entry(DateTime(2026, 10, 23), 13, 17), // Friday
      entry(DateTime(2026, 10, 24), 9, 18), // Saturday: a holiday
      entry(DateTime(2026, 10, 26), 9, 12), // next Monday
    ];
    expect(weekOf(DateTime(2026, 10, 25)), monday);
    expect(weekHours(entries, monday), 7);
  });

  test('times overlap only on the same day and only when they cross', () {
    final existing = [entry(monday, 10, 12)];
    expect(overlapOf(entry(monday, 11, 13), existing), isNotNull);
    expect(overlapOf(entry(monday, 12, 14), existing), isNull);
    expect(
      overlapOf(entry(DateTime(2026, 10, 20), 10, 12), existing),
      isNull,
    );
  });
}
