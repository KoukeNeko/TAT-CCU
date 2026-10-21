import 'dart:io';

import 'package:clock/clock.dart' as clk;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import '../../domain/models/course.dart';
import '../../domain/models/timetable.dart';
import '../../l10n/l10n.dart';
import '../repositories/app_settings.dart';
import '../repositories/ecourse_repository.dart';

/// Moodle only pushes to the official app, so notifications here are local:
/// reminders scheduled from deadlines and the timetable, and a background
/// check (BGAppRefresh, whenever iOS runs it) for new notices and mail.
class Reminders {
  const Reminders._();

  /// Also listed in Info.plist and registered in AppDelegate.swift.
  static const backgroundTask = 'io.github.koukeneko.tatCcu.refresh';

  /// Scheduled reminders use ids below this; new-message alerts above it.
  static const _newsIds = 1000;

  /// iOS keeps at most 64 pending notifications per app.
  static const _maxPending = 60;
  static const _seenKey = 'news_seen';

  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _details = NotificationDetails(
    iOS: DarwinNotificationDetails(),
    android: AndroidNotificationDetails('reminders', 'TAT CCU'),
  );

  static Future<void> init() async {
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    tz.initializeTimeZones();
    // Class times are Taiwan wall-clock times.
    tz.setLocalLocation(tz.getLocation('Asia/Taipei'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Asked for when the student turns a notification on, not at launch.
        iOS: darwin,
        macOS: darwin,
      ),
    );
  }

  /// False when the student declined in the system prompt.
  static Future<bool> requestPermission() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ??
        await android?.requestNotificationsPermission() ??
        false;
  }

  /// Replaces the scheduled reminders with ones for [courses] and [due].
  static Future<void> schedule({
    required List<Course> courses,
    required List<DueItem> due,
    required AppSettings settings,
  }) async {
    for (final p in await _plugin.pendingNotificationRequests()) {
      if (p.id < _newsIds) await _plugin.cancel(id: p.id);
    }
    final l10n = l10nFor(settings.locale);
    for (final r in remindersFor(
      courses: courses,
      due: due,
      now: clk.clock.now(),
      dueOn: settings.notifyDue,
      classOn: settings.notifyClass,
      l10n: l10n,
    ).take(_maxPending)) {
      await _plugin.zonedSchedule(
        id: r.id,
        scheduledDate: tz.TZDateTime.from(r.at, tz.local),
        title: r.title,
        body: r.body,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Fetches what [schedule] needs; for settings changes and the background.
  static Future<void> sync(EcourseRepository repo, AppSettings settings) async {
    final (courses, due) = await (
      repo.currentCourses(),
      repo.dueSoon(days: 7),
    ).wait;
    await schedule(courses: courses, due: due, settings: settings);
  }

  /// Alerts for notices and mail newer than the last check. The first check
  /// only remembers the time, so turning this on does not replay old ones.
  static Future<void> checkNews(
    EcourseRepository repo,
    AppSettings settings,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getInt(_seenKey);
    final (notices, mail) = await (repo.notices(), repo.inbox()).wait;
    final l10n = l10nFor(settings.locale);
    final fresh = [
      for (final n in notices)
        if (!n.read && seen != null && n.time.millisecondsSinceEpoch > seen)
          (time: n.time, title: n.subject, body: n.text),
      for (final m in mail)
        if (m.unread && seen != null && m.time.millisecondsSinceEpoch > seen)
          (time: m.time, title: l10n.newMailFrom(m.sender), body: m.subject),
    ]..sort((a, b) => a.time.compareTo(b.time));
    for (final n in fresh) {
      await _plugin.show(
        id: _newsIds + n.time.millisecondsSinceEpoch ~/ 1000 % 100000,
        title: n.title,
        body: n.body,
        notificationDetails: _details,
      );
    }
    final latest = [
      ...notices.map((n) => n.time),
      ...mail.map((m) => m.time),
    ].fold(clk.clock.now(), (a, b) => b.isAfter(a) ? b : a);
    await prefs.setInt(_seenKey, latest.millisecondsSinceEpoch);
  }

  /// Runs the background check every hour or so, as iOS allows, while any
  /// notification is on or a home screen widget needs fresh [widgets] data.
  static Future<void> updateBackground(
    AppSettings settings, {
    bool widgets = false,
  }) async {
    final on =
        widgets ||
        settings.notifyDue ||
        settings.notifyClass ||
        settings.notifyNews;
    // Background refresh is a phone feature; desktop refreshes when opened.
    if (!(Platform.isIOS || Platform.isAndroid)) return;
    if (on) {
      await Workmanager().registerPeriodicTask(
        backgroundTask,
        backgroundTask,
        frequency: const Duration(hours: 1),
        initialDelay: const Duration(hours: 1),
      );
    } else {
      await Workmanager().cancelByUniqueName(backgroundTask);
    }
  }
}

typedef Reminder = ({int id, DateTime at, String title, String body});

/// Ten minutes before [session] on the day [day] days from [now], if the
/// session falls on that weekday and the time is still ahead.
DateTime? _classReminder(DateTime now, int day, ClassSession session) {
  final date = DateTime(now.year, now.month, now.day + day);
  if (date.weekday != session.weekday) return null;
  final at = date.add(Duration(minutes: session.start - 10));
  return at.isAfter(now) ? at : null;
}

/// Deadlines 24 hours and 1 hour ahead, classes 10 minutes ahead, over the
/// next week, soonest first.
List<Reminder> remindersFor({
  required List<Course> courses,
  required List<DueItem> due,
  required DateTime now,
  required bool dueOn,
  required bool classOn,
  required AppLocalizations l10n,
}) {
  final chinese = l10n.localeName == 'zh';
  final out = <({DateTime at, String title, String body})>[
    if (dueOn)
      for (final d in due)
        for (final (lead, label) in [
          (const Duration(hours: 24), l10n.reminderDue24),
          (const Duration(hours: 1), l10n.reminderDue1),
        ])
          if (d.due.subtract(lead).isAfter(now))
            (
              at: d.due.subtract(lead),
              title: d.name,
              body: '$label・${courseNameIn(d.course, chinese: chinese)}',
            ),
    if (classOn)
      for (var day = 0; day < 7; day++)
        for (final c in courses)
          for (final session in c.sessions)
            if (_classReminder(now, day, session) case final at?)
              (
                at: at,
                title: c.name(chinese: chinese),
                body: [l10n.reminderClass, ?c.room].join('・'),
              ),
  ]..sort((a, b) => a.at.compareTo(b.at));
  return [
    for (final (i, r) in out.indexed)
      (id: i + 1, at: r.at, title: r.title, body: r.body),
  ];
}
