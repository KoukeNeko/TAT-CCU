import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart' as clk;
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../../data/repositories/app_settings.dart';
import '../../data/repositories/ecourse_auth_repository.dart';
import '../../data/repositories/ecourse_repository.dart';
import '../../data/services/school_calendar.dart';
import '../../domain/models/course.dart';
import '../../domain/models/timetable.dart';
import '../../l10n/l10n.dart';
import '../core/format.dart';
import '../core/theme.dart';

/// Home screen widgets (design/round-11/home-widgets.html), drawn natively
/// by ios/TatWidgets and the providers in android/.../widgets. They cannot
/// reach eCourse2, so the app writes what they show over the coming week as
/// frames, each shown from its `at` until the next; the native side picks
/// the current frame and only works out the minutes left in a class.
abstract final class HomeWidgets {
  /// Also in both iOS targets' entitlements.
  static const appGroup = 'group.io.github.koukeneko.tatCcu';

  /// Read under this key by the native widgets.
  static const dataKey = 'widget_data';

  /// The widget kinds in ios/TatWidgets.
  static const _iosKinds = [
    'NextClass',
    'TodayClasses',
    'DueSoon',
    'Countdown',
  ];

  /// The AppWidgetProviders in MainActivity's package.
  static const _androidProviders = [
    'NextClassWidget',
    'TodayWidget',
    'OverviewWidget',
    'DueWidget',
    'CountdownWidget',
  ];

  /// Home-screen widgets exist only on the phone platforms.
  static bool get _supported => Platform.isIOS || Platform.isAndroid;

  static Future<bool> installed() async =>
      _supported && (await HomeWidget.getInstalledWidgets()).isNotEmpty;

  /// Rewrites the frames from the cached or fresh timetable and deadlines.
  static Future<void> sync(
    EcourseAuthRepository auth,
    AppSettings settings,
  ) async {
    if (!_supported) return;
    var courses = <Course>[];
    var due = <DueItem>[];
    if (auth.isSignedIn) {
      final repo = EcourseRepository(auth.client());
      // Two weeks, so later frames still list a full week ahead.
      (courses, due) = await (
        repo.currentCourses(),
        repo.dueSoon(days: 14),
      ).wait;
    }
    final tones = Tones.of(Brightness.dark);
    final data = widgetData(
      courses: courses,
      due: due,
      now: clk.clock.now(),
      l10n: l10nFor(settings.locale),
      signedIn: auth.isSignedIn,
      courseColor: (id) => tones.forCourse(id).strong,
    );
    await HomeWidget.setAppGroupId(appGroup);
    await HomeWidget.saveWidgetData(dataKey, jsonEncode(data));
    if (Platform.isIOS) {
      for (final kind in _iosKinds) {
        await HomeWidget.updateWidget(iOSName: kind);
      }
      return;
    }
    // Android has no timeline: it redraws at each frame and, during a
    // class, every five minutes for the minutes left.
    final times = <DateTime>[
      for (final f in data['frames'] as List<Map<String, Object?>>) ...[
        DateTime.fromMillisecondsSinceEpoch(f['at'] as int),
        if ((f['class'] as Map)['end'] case final int end)
          for (var t = (f['at'] as int) + 5 * 60000; t < end; t += 5 * 60000)
            DateTime.fromMillisecondsSinceEpoch(t),
      ],
    ];
    for (final name in _androidProviders) {
      // The classes keep the app's namespace while a dev build's package
      // gets a suffix, so the name is given whole.
      final qualified = 'io.github.koukeneko.tat_ccu.$name';
      await HomeWidget.updateWidget(qualifiedAndroidName: qualified);
      await HomeWidget.scheduleWidgetUpdates(
        times,
        qualifiedAndroidName: qualified,
      );
    }
  }
}

/// What the widgets show from [now] for a week: shared labels plus one
/// frame per moment something changes (midnight, a class starting or
/// ending, a deadline passing).
Map<String, Object?> widgetData({
  required List<Course> courses,
  required List<DueItem> due,
  required DateTime now,
  required AppLocalizations l10n,
  required bool signedIn,
  required Color Function(int courseId) courseColor,
}) {
  final chinese = l10n.localeName == 'zh';
  final end = now.add(const Duration(days: 7));
  DateTime dayAt(DateTime d, int minutes) =>
      DateTime(d.year, d.month, d.day).add(Duration(minutes: minutes));
  String weekday(DateTime d) => l10n.weekdayFull('${d.weekday}');
  String hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  List<(Course, ClassSession)> slotsOn(DateTime day) => [
    for (final c in courses)
      for (final s in c.sessions)
        if (s.weekday == day.weekday) (c, s),
  ]..sort((a, b) => a.$2.start.compareTo(b.$2.start));

  Map<String, Object?> slot(Course c, ClassSession s) => {
    'name': c.name(chinese: chinese),
    'room': c.room,
    'time': clock(s.start),
    'color': hex(courseColor(c.id)),
  };

  Map<String, Object?> frame(DateTime t) {
    final day = DateTime(t.year, t.month, t.day);
    final minute = t.hour * 60 + t.minute;
    final slots = slotsOn(day);
    final remaining = [
      for (final x in slots)
        if (x.$2.end > minute) x,
    ];
    final current = remaining.where((x) => x.$2.start <= minute).firstOrNull;
    final next = remaining.where((x) => x.$2.start > minute).firstOrNull;
    final headline = slots.isEmpty
        ? l10n.todayNoClasses
        : remaining.isEmpty
        ? l10n.todayClassesOver
        : l10n.todayClassesLeft('${remaining.length}');

    final Map<String, Object?> cls;
    if (current case (final c, final s)?) {
      cls = {
        ...slot(c, s),
        'label': l10n.inClass,
        'until': l10n.untilTime(clock(s.end)),
        'start': dayAt(day, s.start).millisecondsSinceEpoch,
        'end': dayAt(day, s.end).millisecondsSinceEpoch,
      };
    } else if (next case (final c, final s)?) {
      cls = {...slot(c, s), 'label': l10n.nextClass};
    } else {
      cls = {'label': headline};
      for (var d = 1; d <= 7; d++) {
        final other = DateTime(day.year, day.month, day.day + d);
        if (slotsOn(other).firstOrNull case (final c, final s)?) {
          cls.addAll({
            ...slot(c, s),
            'sub': l10n.firstClassOn(d == 1 ? l10n.tomorrow : weekday(other)),
          });
          break;
        }
      }
    }

    String when(DateTime d) {
      final time = clock(d.hour * 60 + d.minute);
      return switch (DateTime(d.year, d.month, d.day).difference(day).inDays) {
        0 => '${l10n.today} $time',
        1 => '${l10n.tomorrow} $time',
        _ => '${monthDay(d)} ${weekday(d)}',
      };
    }

    final open = [
      for (final d in due)
        if (d.due.isAfter(t) && d.due.isBefore(t.add(const Duration(days: 7))))
          d,
    ];
    final school = nextSchoolDate(t);
    final days = school?.start.difference(day).inDays;
    final term = termProgress(day);
    return {
      'at': t.millisecondsSinceEpoch,
      'class': cls,
      'day': {
        'date': '${monthDay(day)} ${weekday(day)}',
        'count': remaining.length,
        'headline': headline,
        'rows': [
          for (final (c, s) in remaining)
            {...slot(c, s), 'now': s.start <= minute},
        ],
      },
      'due': {
        'count': open.length,
        'rows': [
          for (final d in open.take(3))
            {
              'name': d.name,
              'course': courseNameIn(d.course, chinese: chinese),
              'when': when(d.due),
            },
        ],
      },
      if (school != null && days != null)
        'countdown': {
          'title': school.title,
          'value': days <= 0 ? l10n.countdownToday : '$days',
          'unit': days <= 0 ? null : l10n.daysUnit,
          'date': '${monthDay(school.start)} ${weekday(school.start)}',
          if (term != null) ...{
            'week': l10n.termWeekShort(term.week, term.weeks),
            'progress': term.progress,
          },
        },
    };
  }

  final times = <DateTime>{
    now,
    for (var d = 1; d <= 7; d++) DateTime(now.year, now.month, now.day + d),
    for (var d = 0; d < 7; d++)
      for (final (_, s) in slotsOn(
        DateTime(now.year, now.month, now.day + d),
      )) ...[
        dayAt(DateTime(now.year, now.month, now.day + d), s.start),
        dayAt(DateTime(now.year, now.month, now.day + d), s.end),
      ],
    for (final d in due) d.due,
  }.where((t) => !t.isBefore(now) && t.isBefore(end)).toList()..sort();

  return {
    'signedIn': signedIn,
    'labels': {
      'nextClass': l10n.nextClass,
      'toDo': l10n.toDo,
      'dueThisWeek': l10n.dueThisWeek,
      'countdown': l10n.toolCountdown,
      'countdownEnded': l10n.countdownEnded,
      'upcoming': l10n.countdownUpcoming,
      'nothingDue': l10n.nothingDueThisWeek,
      'signedOut': l10n.ecourseSignedOut,
      'classes': l10n.classesUnit,
      'items': l10n.itemsUnit,
      'minutes': l10n.unitMinutes,
    },
    'frames': [for (final t in times) frame(t)],
  };
}
