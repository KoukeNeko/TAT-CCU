import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/domain/models/course.dart';
import 'package:tat_ccu/domain/models/timetable.dart';
import 'package:tat_ccu/ui/timetable/timetable_screen.dart';

DaySlot _slot(int id, int start, int end) => (
  course: Course(id: id, shortName: '115_1_$id', fullName: 'c$id'),
  session: ClassSession(
    weekday: 2,
    periods: const ['C'],
    start: start,
    end: end,
  ),
);

void main() {
  final morning = _slot(1, 615, 780); // 10:15–13:00
  final afternoon = _slot(2, 795, 960); // 13:15–16:00
  final slots = [morning, afternoon];

  test('in class: that class leads, the next one gets its card', () {
    final r = dayFocus(slots, today: true, minute: 665);
    expect((r.focus, r.after), (morning, afternoon));
  });

  test('before the first class: it leads alone, no second 下一堂', () {
    final r = dayFocus(slots, today: true, minute: 480);
    expect((r.focus, r.after), (morning, null));
  });

  test('between classes the next one leads', () {
    expect(dayFocus(slots, today: true, minute: 785).focus, afternoon);
  });

  test('after the last class: the day reads like any other', () {
    final r = dayFocus(slots, today: true, minute: 1000);
    expect((r.focus, r.after), (morning, null));
  });

  test('another day: the first class, alone', () {
    final r = dayFocus(slots, today: false, minute: 665);
    expect((r.focus, r.after), (morning, null));
  });

  test('numbered periods read as a range, lettered ones joined', () {
    expect(periodLabel(['8', '9']), '8–9');
    expect(periodLabel(['C', 'D']), 'CD');
    expect(periodLabel(['3']), '3');
  });
}
