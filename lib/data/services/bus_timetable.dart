/// Timetables and fares of the highway buses that pass the school, kept in
/// assets/bus_timetable.txt so a change is copied in from the highway
/// bureau's pages rather than written as code; the file's header explains
/// the format.
library;

import 'package:flutter/services.dart';

typedef BusRoute = ({
  String number,

  /// The highway bureau's route code, for its live page.
  String code,
  String name,
});

/// One scheduled departure from [stop], the start of [direction].
typedef BusTrip = ({
  String route,
  String direction,
  String stop,

  /// Minutes after midnight.
  int time,

  /// 1 = Monday ... 7 = Sunday, as [DateTime.weekday].
  Set<int> weekdays,

  /// The first day it runs, for a timetable that starts later.
  DateTime? startsOn,
});

/// Fare from [stop] to the school, in NT dollars.
typedef BusFare = ({String route, String stop, int full, int half});

typedef BusTimetable = ({
  List<BusRoute> routes,
  List<BusTrip> trips,
  List<BusFare> fares,
  Map<String, String> notes,
});

const busTimetableAsset = 'assets/bus_timetable.txt';

Future<BusTimetable> loadBusTimetable() async =>
    parseBusTimetable(await rootBundle.loadString(busTimetableAsset));

/// Throws a [FormatException] naming the first line it cannot read.
BusTimetable parseBusTimetable(String source) {
  final routes = <BusRoute>[];
  final trips = <BusTrip>[];
  final fares = <BusFare>[];
  final notes = <String, String>{};
  final route = RegExp(r'^路線 (\S+) (\S+) (.+)$');
  final fare = RegExp(r'^票價 (\S+) (\S+) (\d+) (\d+)$');
  final note = RegExp(r'^備註 (\S+) (.+)$');
  final trip = RegExp(
    r'^(\S+) (\S+) (\S+) (\d{2}):(\d{2}) ([\d,-]+)(?: (\d{4}-\d{2}-\d{2}))?$',
  );
  for (final raw in source.split('\n')) {
    final text = raw.split('#').first.trim();
    if (text.isEmpty) continue;
    if (route.firstMatch(text) case final m?) {
      routes.add((number: m[1]!, code: m[2]!, name: m[3]!));
    } else if (fare.firstMatch(text) case final m?) {
      fares.add((
        route: m[1]!,
        stop: m[2]!,
        full: int.parse(m[3]!),
        half: int.parse(m[4]!),
      ));
    } else if (note.firstMatch(text) case final m?) {
      notes[m[1]!] = m[2]!;
    } else if (trip.firstMatch(text) case final m?
        when int.parse(m[4]!) < 24 && int.parse(m[5]!) < 60) {
      final weekdays = _weekdays(m[6]!);
      final startsOn = m[7] == null ? null : DateTime.tryParse(m[7]!);
      if (weekdays == null || (m[7] != null && startsOn == null)) {
        throw FormatException('bus timetable: $raw');
      }
      trips.add((
        route: m[1]!,
        direction: m[2]!,
        stop: m[3]!,
        time: int.parse(m[4]!) * 60 + int.parse(m[5]!),
        weekdays: weekdays,
        startsOn: startsOn,
      ));
    } else {
      throw FormatException('bus timetable: $raw');
    }
  }
  return (routes: routes, trips: trips, fares: fares, notes: notes);
}

/// `1-6`, `7` or `1,3,5`; null when a day is outside 1–7.
Set<int>? _weekdays(String spec) {
  final days = <int>{};
  for (final part in spec.split(',')) {
    final ends = part.split('-').map(int.tryParse).toList();
    if (ends.length > 2 || ends.any((d) => d == null || d < 1 || d > 7)) {
      return null;
    }
    for (var d = ends.first!; d <= ends.last!; d++) {
      days.add(d);
    }
  }
  return days;
}

/// Whether [trip] runs on the calendar day [day].
bool runsOn(BusTrip trip, DateTime day) =>
    trip.weekdays.contains(day.weekday) &&
    !(trip.startsOn?.isAfter(day) ?? false);

/// The next departure of each route and direction after [now], within a
/// week, in timetable order.
List<({BusTrip trip, DateTime at})> nextDepartures(
  List<BusTrip> trips,
  DateTime now,
) {
  final next = <(String, String), ({BusTrip trip, DateTime at})>{};
  for (final trip in trips) {
    for (var d = 0; d < 8; d++) {
      final day = DateTime(now.year, now.month, now.day + d);
      if (!runsOn(trip, day)) continue;
      final at = day.add(Duration(minutes: trip.time));
      if (!at.isAfter(now)) continue;
      final key = (trip.route, trip.direction);
      if (next[key] case final known? when !at.isBefore(known.at)) break;
      next[key] = (trip: trip, at: at);
      break;
    }
  }
  return next.values.toList();
}
