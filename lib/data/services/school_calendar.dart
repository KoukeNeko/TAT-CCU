/// Key dates from CCU's 115 academic year calendar
/// (https://www.ccu.edu.tw/var/file/0/1000/img/570/332785444.pdf, listed on
/// https://www.ccu.edu.tw/p/412-1000-1078.php). Only what a student counts
/// down to: classes, exams, add/drop and withdrawal deadlines, days off.
// shortcut: typed in by hand once a year; add the next year's PDF when the
// school publishes it.
library;

typedef SchoolDate = ({DateTime start, DateTime? end, String title});

SchoolDate _d(int y, int m, int d, String title, [DateTime? end]) =>
    (start: DateTime(y, m, d), end: end, title: title);

final schoolCalendar = <SchoolDate>[
  _d(2026, 9, 7, '第 1 學期上課開始'),
  _d(2026, 9, 7, '加退選（第二階段）', DateTime(2026, 9, 18)),
  _d(2026, 9, 25, '中秋節'),
  _d(2026, 9, 28, '孔子誕辰紀念日'),
  _d(2026, 10, 9, '國慶日補假'),
  _d(2026, 10, 16, '休學退費達 1/3 基準日'),
  _d(2026, 10, 26, '臺灣光復節補假'),
  _d(2026, 11, 2, '期中考試週', DateTime(2026, 11, 8)),
  _d(2026, 11, 7, '校慶運動會'),
  _d(2026, 11, 9, '科目棄選開始'),
  _d(2026, 11, 27, '休學退費達 2/3 基準日'),
  _d(2026, 12, 7, '科目棄選截止'),
  _d(2026, 12, 25, '行憲紀念日'),
  _d(2026, 12, 31, '第 1 學期上課最後一天'),
  _d(2027, 1, 1, '中華民國開國紀念日'),
  _d(2027, 1, 2, '期末考試', DateTime(2027, 1, 8)),
  _d(2027, 1, 31, '第 1 學期結束'),
  _d(2027, 2, 22, '第 2 學期上課開始'),
  _d(2027, 2, 22, '加退選（第二階段）', DateTime(2027, 3, 5)),
  _d(2027, 3, 1, '和平紀念日補假'),
  _d(2027, 4, 2, '補運動會活動未放假'),
  _d(2027, 4, 5, '兒童節、民族掃墓節', DateTime(2027, 4, 6)),
  _d(2027, 4, 7, '校際活動（停課）', DateTime(2027, 4, 8)),
  _d(2027, 4, 12, '期中考試週', DateTime(2027, 4, 18)),
  _d(2027, 4, 19, '科目棄選開始'),
  _d(2027, 4, 30, '勞動節補假'),
  _d(2027, 5, 24, '科目棄選截止'),
  _d(2027, 6, 5, '畢業典禮'),
  _d(2027, 6, 9, '端午節'),
  _d(2027, 6, 18, '第 2 學期上課最後一天'),
  _d(2027, 6, 21, '期末考試', DateTime(2027, 6, 27)),
  _d(2027, 7, 31, '第 2 學期結束'),
];

/// Semester spans, for how far along the term is.
final schoolTerms = <({DateTime start, DateTime end})>[
  (start: DateTime(2026, 9, 7), end: DateTime(2027, 1, 8)),
  (start: DateTime(2027, 2, 22), end: DateTime(2027, 6, 27)),
];

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
