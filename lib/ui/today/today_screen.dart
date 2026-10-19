import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/campus_cache.dart';
import '../../data/repositories/ecourse_repository.dart';
import '../../domain/models/course.dart';
import '../../domain/models/timetable.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../more/library_screen.dart';
import '../../l10n/l10n.dart';

// Layout follows design/round-11/today-c-variants.html C1: headline, one
// hero block, a pill for the class after it, then four status tiles.

typedef _Slot = ({Course course, ClassSession session});

typedef _Today = ({
  List<Course> courses,
  List<DueItem> due,
  int notices,
  int mail,
  CachedPage? library,
});

/// `創新大樓 322` → `322`; the pill only has room for the room number.
String _roomNumber(String? room) =>
    RegExp(r'\d+\S*$').stringMatch(room ?? '') ?? (room ?? '');

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

/// The tab stays alive in the shell, so the countdown cannot rely on being
/// rebuilt: it ticks at each minute and when the app comes back.
class _TodayScreenState extends State<TodayScreen> {
  Timer? _tick;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _schedule);
    _schedule();
  }

  /// Rebuilds now and again on the next minute boundary.
  void _schedule() {
    _tick?.cancel();
    if (mounted) setState(() {});
    final now = DateTime.now();
    _tick = Timer(
      Duration(seconds: 60 - now.second, milliseconds: -now.millisecond),
      _schedule,
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  Future<_Today> _load(EcourseRepository repo) async {
    final results = await Future.wait([
      repo.currentCourses(),
      repo.dueSoon(days: 7),
      repo.unreadNotices(),
      repo.unreadMail(),
    ]);
    return (
      courses: results[0] as List<Course>,
      due: results[1] as List<DueItem>,
      notices: results[2] as int,
      mail: results[3] as int,
      library: await CampusCache.read(LibraryScreen.cacheKey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    final now = DateTime.now();
    return Scaffold(
      // Edge to edge: the list itself pads past the status bar.
      body: Loader<_Today>.watch(
        watch: () => repo.watch(_load),
        builder: (context, d) {
          // Today's classes from the current day, so midnight moves on too.
          final slots = [
            for (final c in d.courses)
              for (final s in c.sessions)
                if (s.weekday == now.weekday) (course: c, session: s),
          ]..sort((a, b) => a.session.start.compareTo(b.session.start));
          final minute = now.hour * 60 + now.minute;
          final remaining = slots.where((s) => s.session.end > minute).toList();
          final current = remaining
              .where((s) => s.session.start <= minute)
              .firstOrNull;
          final next = remaining
              .where((s) => s.session.start > minute)
              .firstOrNull;
          final theme = Theme.of(context);
          final tones = context.tones;
          final n = remaining.length;
          final l10n = context.l10n;
          final headline = slots.isEmpty
              ? l10n.todayNoClasses
              : n == 0
              ? l10n.todayClassesOver
              : l10n.todayClassesLeft('$n');
          final hero = current ?? next;
          final after = hero == null
              ? null
              : remaining.skipWhile((s) => s != hero).skip(1).firstOrNull;
          final loan = loanStatus(l10n, d.library);
          return ListView(
            padding: scrollPadding(context),
            children: [
              // Header design A (design/round-09): date above; the headline
              // and the bell share one line, centered on each other.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weekdayName(context, now.weekday)} ${now.month}/${now.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            headline,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _BellButton(
                          unread: d.notices + d.mail,
                          onTap: () => context.push('/today/notifications'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (current != null)
                _Hero(
                  slot: current,
                  label: l10n.inClass,
                  detail: l10n.untilTime(clock(current.session.end)),
                  minutes: current.session.end - minute,
                  later: false,
                )
              else if (next != null)
                _Hero(
                  slot: next,
                  label: l10n.nextClass,
                  detail: l10n.startsAt(clock(next.session.start)),
                  minutes: next.session.start - minute,
                  later: true,
                ),
              if (after != null) ...[
                const SizedBox(height: 10),
                _AfterPill(slot: after),
              ],
              const SizedBox(height: rowGap),
              for (final (i, row) in [
                [
                  StatusTile(
                    tone: tones.peach,
                    icon: Icons.assignment_outlined,
                    title: l10n.dueThisWeek,
                    status: '${d.due.length}',
                    onTap: () => context.push('/today/due'),
                  ),
                  StatusTile(
                    tone: tones.sun,
                    icon: Icons.notifications_none,
                    title: l10n.unread,
                    status: '${d.notices + d.mail}',
                    onTap: () => context.push('/today/notifications'),
                  ),
                ],
                [
                  StatusTile(
                    tone: loan?.overdue == true ? tones.peach : tones.mint,
                    icon: Icons.menu_book_outlined,
                    title: l10n.library,
                    status: loan?.text,
                    onTap: () => context.push('/more/library'),
                  ),
                  StatusTile(
                    tone: tones.lilac,
                    icon: Icons.qr_code_2,
                    title: l10n.studySpace,
                    onTap: () => context.push('/more/space'),
                  ),
                ],
              ].indexed) ...[
                if (i > 0) const SizedBox(height: rowGap),
                Row(
                  children: [
                    Expanded(child: row[0]),
                    const SizedBox(width: rowGap),
                    Expanded(child: row[1]),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.slot,
    required this.label,
    required this.detail,
    required this.minutes,
    required this.later,
  });

  final _Slot slot;
  final String label, detail;
  final int minutes;

  /// Counting down to the start rather than to the end.
  final bool later;

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.lilac;
    final l10n = context.l10n;
    // Past an hour, minutes are hard to read: 557 → 9 小時後.
    final hours = minutes >= 60;
    final count = hours ? minutes ~/ 60 : minutes;
    final unit = switch ((hours, later)) {
      (true, true) => l10n.unitHoursLater,
      (true, false) => l10n.unitHours,
      (false, true) => l10n.unitMinutesLater,
      (false, false) => l10n.unitMinutes,
    };
    return Material(
      color: tone.fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corners.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/courses/${slot.course.id}'),
        child: SizedBox(
          height: 226,
          child: Stack(
            children: [
              // The badge sits partly outside the card, as in the mockup,
              // centred behind the count below.
              Positioned(
                right: -25,
                bottom: -32,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: ShapeDecoration(
                    color: tone.strong,
                    shape: const StarBorder(
                      points: 11,
                      innerRadiusRatio: 0.78,
                      pointRounding: 0.15,
                      valleyRounding: 0.1,
                    ),
                  ),
                ),
              ),
              // Count with its unit beside it; the unit's side bearing makes a
              // smaller right inset read the same as the bottom one.
              Positioned(
                right: 20,
                bottom: 26,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        color: tone.fill,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      unit,
                      style: TextStyle(
                        color: tone.fill,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 120, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: ShapeDecoration(
                        color: tone.strong,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: tone.fill,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.courseName(slot.course),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tone.ink,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${slot.course.room ?? ''}・$detail',
                      style: TextStyle(
                        color: tone.ink.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The class after the hero's: its time, name and room on one line.
class _AfterPill extends StatelessWidget {
  const _AfterPill({required this.slot});

  final _Slot slot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const bold = TextStyle(fontSize: 14, fontWeight: FontWeight.w800);
    return Material(
      color: scheme.surfaceContainerLow,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/courses/${slot.course.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: context.tones.forCourse(slot.course.id).strong,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(clock(slot.session.start), style: bold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.courseName(slot.course),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bold,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _roomNumber(slot.course.room),
                style: bold.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Notifications live behind this bell instead of a nav tab; the badge is
/// the same unread count as the 未讀 tile.
class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread, required this.onTap});

  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sun = context.tones.sun;
    return Semantics(
      button: true,
      label: unread > 0
          ? context.l10n.notificationsUnread(unread)
          : context.l10n.notifications,
      child: Material(
        color: scheme.surfaceContainer,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_none, color: scheme.onSurface),
                if (unread > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: ShapeDecoration(
                        color: sun.strong,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: TextStyle(
                          color: sun.fill,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
