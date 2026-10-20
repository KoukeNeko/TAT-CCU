/// CCU's academic calendar (校務行事曆), kept in assets/school_calendar.txt
/// so a new year is copied in from the school's PDF rather than written as
/// code; the file's header explains the format.
library;

import 'package:flutter/services.dart';

typedef SchoolDate = ({DateTime start, DateTime? end, String title});

typedef SchoolCalendar = ({
  List<SchoolDate> dates,
  List<({DateTime start, DateTime end})> terms,
});

/// Parses [source] in the format of assets/school_calendar.txt, dates
/// sorted.
/// Throws a [FormatException] naming the first line it cannot read.
SchoolCalendar parseSchoolCalendar(String source) {
  final dates = <SchoolDate>[];
  final terms = <({DateTime start, DateTime end})>[];
  final line = RegExp(
    r'^(學期 )?(\d{4}-\d{2}-\d{2})(?:~(\d{4}-\d{2}-\d{2}))?(?: (.+))?$',
  );
  for (final raw in source.split('\n')) {
    final text = raw.split('#').first.trim();
    if (text.isEmpty) continue;
    final m = line.firstMatch(text);
    final start = DateTime.tryParse(m?[2] ?? '');
    final end = m?[3] == null ? null : DateTime.tryParse(m![3]!);
    final term = m?[1] != null;
    if (m == null ||
        start == null ||
        (m[3] != null && (end == null || end.isBefore(start))) ||
        (term ? end == null || m[4] != null : m[4] == null)) {
      throw FormatException('school calendar: $raw');
    }
    if (term) {
      terms.add((start: start, end: end!));
    } else {
      dates.add((start: start, end: end, title: m[4]!.trim()));
    }
  }
  dates.sort((a, b) => a.start.compareTo(b.start));
  terms.sort((a, b) => a.start.compareTo(b.start));
  return (dates: dates, terms: terms);
}

/// Asset holding the calendar.
const schoolCalendarAsset = 'assets/school_calendar.txt';

late SchoolCalendar _calendar;

/// Reads the calendar; before anything uses it, in each isolate.
Future<void> loadSchoolCalendar() async {
  _calendar = parseSchoolCalendar(
    await rootBundle.loadString(schoolCalendarAsset),
  );
}

List<SchoolDate> get schoolCalendar => _calendar.dates;

/// Semester spans, for how far along the term is.
List<({DateTime start, DateTime end})> get schoolTerms => _calendar.terms;

/// The next calendar date still to come, counting one in progress.
SchoolDate? nextSchoolDate(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return schoolCalendar
      .where((d) => !(d.end ?? d.start).isBefore(today))
      .firstOrNull;
}

/// How far into its semester [day] is, or null outside the semesters.
({int week, int weeks, double progress})? termProgress(DateTime day) {
  final term = schoolTerms
      .where((s) => !day.isBefore(s.start) && !day.isAfter(s.end))
      .firstOrNull;
  if (term == null) return null;
  final done = day.difference(term.start).inDays;
  final length = term.end.difference(term.start).inDays;
  return (
    week: done ~/ 7 + 1,
    weeks: (length / 7).ceil(),
    progress: done / length,
  );
}
