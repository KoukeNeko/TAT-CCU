import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/data/services/bus_timetable.dart';

void main() {
  test('the timetable asset parses', () {
    final timetable = parseBusTimetable(
      File(busTimetableAsset).readAsStringSync(),
    );
    final numbers = [for (final r in timetable.routes) r.number];
    expect(numbers, ['7309', '7306', '106', '7005B']);
    expect(timetable.trips.map((t) => t.route).toSet(), numbers.toSet());
    expect(timetable.trips.where((t) => t.route == '7309'), hasLength(32));
    expect(timetable.fares.where((f) => f.route == '7309').first, (
      route: '7309',
      stop: '嘉義火車站',
      full: 53,
      half: 27,
    ));
    expect(timetable.notes.keys, ['7005B']);
  });

  test('next departure per direction, by weekday', () {
    final trips = parseBusTimetable('''
7309 往南華大學 大雅站 07:45 1-6
7309 往南華大學 大雅站 08:45 7
7309 往南華大學 大雅站 18:45 1-6
7306 往梅山 民雄國中 07:00 1-5
''').trips;
    // Tuesday 2026-10-20, 10:00.
    final tuesday = nextDepartures(trips, DateTime(2026, 10, 20, 10));
    expect(
      [for (final d in tuesday) (d.trip.route, d.at)],
      [
        ('7309', DateTime(2026, 10, 20, 18, 45)),
        ('7306', DateTime(2026, 10, 21, 7)),
      ],
    );

    // Saturday evening: the next 7309 is Sunday's, the next 7306 Monday's.
    final saturday = nextDepartures(trips, DateTime(2026, 10, 24, 19));
    expect(
      [for (final d in saturday) d.at],
      [DateTime(2026, 10, 25, 8, 45), DateTime(2026, 10, 26, 7)],
    );
  });

  test('a timetable that starts later waits for its first day', () {
    final trips = parseBusTimetable('106 往高鐵嘉義站 嘉義火車站 08:00 1-7 2026-10-24')
        .trips;
    expect(
      nextDepartures(trips, DateTime(2026, 10, 20, 10)).single.at,
      DateTime(2026, 10, 24, 8),
    );
  });

  test('rejects lines it cannot read', () {
    for (final line in [
      '7309 往南華大學 大雅站 7:45 1-6',
      '7309 往南華大學 大雅站 25:00 1-6',
      '7309 往南華大學 大雅站 07:45 0-6',
      '7309 往南華大學 07:45 1-6',
      '106 往嘉義 高鐵嘉義站 10:00 1-7 2026/10/24',
      '票價 7309 嘉義火車站 53',
    ]) {
      expect(
        () => parseBusTimetable(line),
        throwsFormatException,
        reason: line,
      );
    }
  });
}
