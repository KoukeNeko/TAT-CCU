/// Dates, times, sizes and money as the app writes them everywhere.
library;

import 'package:flutter/widgets.dart';

import '../../l10n/l10n.dart';

/// `週一`, `Mon`, `月曜` for weekday 1–7.
String weekdayName(BuildContext context, int weekday) =>
    context.l10n.weekdayFull('$weekday');

/// `115_1` → `115 學年上學期`, `Fall of year 115`, `115学年度 前期`.
String semesterName(BuildContext context, String semester) {
  final parts = semester.split('_');
  if (parts.length < 2) return semester;
  return context.l10n.semesterLabel(parts[0], parts[1]);
}

/// `一`, `Mon`, `月` for weekday 1–7.
String weekdayShort(BuildContext context, int weekday) =>
    context.l10n.weekdayShort('$weekday');

/// Minutes after midnight as `9:05`.
String clock(int minutes) =>
    '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

/// `10/20 週二 9:05`.
String dateTimeLabel(BuildContext context, DateTime t) =>
    '${dayLabel(context, t)} ${clock(t.hour * 60 + t.minute)}';

/// `10/20`.
String monthDay(DateTime d) => '${d.month}/${d.day}';

/// `10/20 9:05`.
String monthDayTime(DateTime d) =>
    '${monthDay(d)} ${clock(d.hour * 60 + d.minute)}';

/// `10/20 週二`.
String dayLabel(BuildContext context, DateTime d) =>
    '${monthDay(d)} ${weekdayName(context, d.weekday)}';

/// The ROC (民國) year the school's systems use: 2026 → 115.
int rocYear(DateTime d) => d.year - 1911;

/// `1,234`.
String grouped(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// `512 B`, `184 KB`, `2.4 MB`.
String fileSize(int bytes) => switch (bytes) {
  < 1024 => '$bytes B',
  < 1024 * 1024 => '${(bytes / 1024).round()} KB',
  _ => '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB',
};
