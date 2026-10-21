/// One class meeting on the weekly timetable.
class ClassSession {
  const ClassSession({
    required this.weekday,
    required this.periods,
    required this.start,
    required this.end,
  });

  /// 1 = Monday ... 7 = Sunday, matching [DateTime.weekday].
  final int weekday;
  final List<String> periods;

  /// Minutes after midnight.
  final int start;
  final int end;
}

const _weekdays = {
  '週一': 1,
  '週二': 2,
  '週三': 3,
  '週四': 4,
  '週五': 5,
  '週六': 6,
  '週日': 7,
};

/// CCU runs two period systems side by side: numbered 50-minute periods
/// (1 = 07:10–08:00, one per hour) and lettered 75-minute periods
/// (A = 07:15–08:30, one every 90 minutes).
({int start, int end})? periodTime(String code) {
  final n = int.tryParse(code);
  if (n != null) {
    if (n < 1 || n > 15) return null;
    final start = (6 + n) * 60 + 10;
    return (start: start, end: start + 50);
  }
  if (code.length != 1) return null;
  final i = code.codeUnitAt(0) - 'A'.codeUnitAt(0);
  if (i < 0 || i > 9) return null;
  final start = 7 * 60 + 15 + i * 90;
  return (start: start, end: start + 75);
}

/// Parses the eCourse2 `schedule` custom field, e.g. `週二 C,D` or
/// `週一 8,9 週四 3`. Unknown tokens are skipped rather than guessed.
List<ClassSession> parseSchedule(String value) {
  final sessions = <ClassSession>[];
  final tokens = value.trim().split(RegExp(r'\s+'));
  for (var i = 0; i + 1 < tokens.length; i++) {
    final weekday = _weekdays[tokens[i]];
    if (weekday == null) continue;
    final codes = tokens[i + 1].split(',').map((c) => c.trim()).toList();
    final times = codes.map(periodTime).toList();
    if (times.isEmpty || times.any((t) => t == null)) continue;
    sessions.add(
      ClassSession(
        weekday: weekday,
        periods: codes,
        start: times.map((t) => t!.start).reduce((a, b) => a < b ? a : b),
        end: times.map((t) => t!.end).reduce((a, b) => a > b ? a : b),
      ),
    );
    i++;
  }
  return sessions;
}
