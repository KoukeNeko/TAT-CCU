import 'dart:async';

import 'package:clock/clock.dart' as clk;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../domain/models/course.dart';
import '../../domain/models/timetable.dart';
import '../core/desktop_mode.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../courses/attendance_scan_screen.dart';
import '../notifications/notifications_screen.dart';
import 'desk_today.dart';
import 'due_screen.dart';
import '../../l10n/l10n.dart';

// Layout follows design/round-11/today-c-variants.html C1: headline, one
// hero block, a card for the class after it, then (today-final.html) what
// is due and what is unread as two short lists.

typedef _Slot = ({Course course, ClassSession session});

typedef _Today = ({
  List<Course> courses,
  List<DueItem> due,
  int notices,
  int mail,
  List<NoticeItem> latest,
});

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
    final now = clk.clock.now();
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
      repo.notices(),
    ]);
    return (
      courses: results[0] as List<Course>,
      due: results[1] as List<DueItem>,
      notices: results[2] as int,
      mail: results[3] as int,
      latest: [
        for (final n in results[4] as List<NoticeItem>)
          if (!n.read) n,
      ].take(3).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    final now = clk.clock.now();
    final desk =
        desktopUi(context) &&
        foldOf(context) == null &&
        MediaQuery.sizeOf(context).width >= splitLayout;
    return Scaffold(
      appBar: desk ? topBar(context.l10n.navToday) : null,
      // Edge to edge: the list itself pads past the status bar.
      body: Loader<_Today>.watch(
        watch: () => repo.watch(_load),
        refreshOn: unreadChanged,
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
          // Once today's classes are over: the next school day's first.
          final upcoming = hero != null
              ? null
              : [
                  for (var day = 1; day <= 7; day++)
                    if ([
                          for (final c in d.courses)
                            for (final s in c.sessions)
                              if (s.weekday == (now.weekday + day - 1) % 7 + 1)
                                (course: c, session: s),
                        ]..sort(
                          (a, b) => a.session.start.compareTo(b.session.start),
                        )
                        case [final first, ...])
                      (slot: first, days: day),
                ].firstOrNull;
          Widget? heroCard({bool cover = false}) => current != null
              ? _Hero(
                  slot: current,
                  label: l10n.inClass,
                  detail: l10n.untilTime(clock(current.session.end)),
                  minutes: current.session.end - minute,
                  later: false,
                  // shortcut: shown in every class, whether or not the course
                  // takes attendance; check its modules if that gets noisy.
                  onAttendance: () => scanAttendance(context),
                  cover: cover,
                )
              : next != null
              ? _Hero(
                  slot: next,
                  label: l10n.nextClass,
                  detail: l10n.startsAt(clock(next.session.start)),
                  minutes: next.session.start - minute,
                  later: true,
                  cover: cover,
                )
              : upcoming != null
              ? _Hero(
                  slot: upcoming.slot,
                  label: l10n.firstClassOn(
                    upcoming.days == 1
                        ? l10n.tomorrow
                        : weekdayName(context, upcoming.slot.session.weekday),
                  ),
                  detail: l10n.startsAt(clock(upcoming.slot.session.start)),
                  minutes:
                      upcoming.days * 24 * 60 +
                      upcoming.slot.session.start -
                      minute,
                  later: true,
                  tone: tones.mint,
                  cover: cover,
                )
              : null;

          final classCards = <Widget>[
            // Header design A (design/round-09): date above the headline;
            // notifications moved to the 訊息 tab.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xs),
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
                  Text(
                    headline,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ?heroCard(),
          ];
          final lead = [
            ...classCards,
            if (after != null) ...[
              const SizedBox(height: rowGap),
              _AfterCard(slot: after),
            ],
          ];
          final dueList = <Widget>[
            if (d.due.isNotEmpty) ...[
              _GroupHeader(
                title: l10n.dueThisWeek,
                count: d.due.length,
                color: tones.peach.strong,
                onAll: () => context.push('/today/due'),
              ),
              for (final (i, item) in d.due.take(3).indexed) ...[
                if (i > 0) const Divider(height: 1),
                _ListRow(
                  // Within two days, as on the due page.
                  dot: item.due.difference(now).inHours < 48
                      ? tones.peach.strong
                      : tones.forCourse(item.courseId).strong,
                  title: item.name,
                  subtitle: context.courseNameOf(item.course),
                  // Within a week, the weekday is enough.
                  trailing:
                      '${weekdayName(context, item.due.weekday)} '
                      '${clock(item.due.hour * 60 + item.due.minute)}',
                  onTap: item.url == null
                      ? null
                      : () => openDueItem(context, item),
                ),
              ],
            ],
          ];
          final unreadList = <Widget>[
            if (d.notices + d.mail > 0) ...[
              _GroupHeader(
                title: l10n.unread,
                count: d.notices + d.mail,
                color: tones.sun.strong,
                onAll: () => context.go('/messages'),
              ),
              for (final (i, n) in d.latest.indexed) ...[
                if (i > 0) const Divider(height: 1),
                _ListRow(
                  dot: tones.sun.strong,
                  title: n.subject,
                  subtitle: dateTimeLabel(context, n.time),
                  onTap: n.url == null
                      ? null
                      : () {
                          markNoticeRead(context, n.id);
                          openEcourseLink(context, n.url!, title: n.subject);
                        },
                ),
              ],
            ],
          ];
          // A flip phone's outer display: the class filling the height,
          // what is due and unread as two counts (design/round-24 C).
          if (coverScreen(context)) {
            final hero = heroCard(cover: true);
            return Padding(
              // Level with the rail, and as far from the bottom.
              padding: scrollPadding(context, top: coverTop).copyWith(
                bottom: MediaQuery.paddingOf(context).bottom + Space.m,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child:
                        hero ??
                        Center(
                          child: Text(
                            headline,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                  ),
                  const SizedBox(height: Space.s),
                  Row(
                    children: [
                      Expanded(
                        child: _CountTile(
                          count: d.due.length,
                          label: l10n.dueThisWeek,
                          onTap: () => context.push('/today/due'),
                        ),
                      ),
                      const SizedBox(width: Space.s),
                      Expanded(
                        child: _CountTile(
                          count: d.notices + d.mail,
                          label: l10n.unread,
                          onTap: () => context.go('/messages'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          if (desk) {
            return DeskToday(
              headline: headline,
              slots: slots.isNotEmpty || upcoming == null
                  ? slots
                  : [upcoming.slot],
              hero: hero ?? upcoming?.slot,
              heroToday: hero != null,
              after: after,
              minute: minute,
              due: d.due,
              latest: d.latest,
              unread: d.notices + d.mail,
            );
          }
          final width = MediaQuery.sizeOf(context).width;
          final fold = foldOf(context);
          // An open foldable: the class on the half left of the fold,
          // what is due and unread on the right half.
          final book = fold?.posture == FoldPosture.book;
          final wide = width >= wideLayout || book;
          final split = width >= splitLayout || book;
          Widget column(List<Widget> children) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
          Widget sideBySide() => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: column(dueList)),
              const SizedBox(width: Space.l),
              Expanded(child: column(unreadList)),
            ],
          );
          final lists = dueList.isEmpty || unreadList.isEmpty
              ? [...dueList, ...unreadList]
              : [sideBySide()];
          // Half-open on a table, or open flat in landscape: the class
          // above the fold, the lists below it.
          if (fold case (:final posture, :final at)
              when posture != FoldPosture.book) {
            final padding = scrollPadding(context, maxWidth: double.infinity);
            // Open flat in landscape the half is too short for the class
            // and the one after it stacked, so they sit side by side
            // (design/round-12 duo-variants B).
            final top = posture == FoldPosture.across && after != null
                ? [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: column(classCards)),
                        const SizedBox(width: Space.l),
                        SizedBox(width: 280, child: _AfterCard(slot: after)),
                      ],
                    ),
                  ]
                : lead;
            return Column(
              children: [
                SizedBox(
                  height: at,
                  // Reversed, so the class sits just above the fold.
                  child: ListView(
                    reverse: true,
                    padding: padding.copyWith(bottom: Space.l),
                    children: top.reversed.toList(),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: padding.copyWith(top: 0),
                    children: width >= railLayout
                        ? lists
                        : [...dueList, ...unreadList],
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: scrollPadding(
              context,
              maxWidth: split ? double.infinity : readableWidth,
            ),
            children: !split
                ? [...lead, ...dueList, ...unreadList]
                // iPad in portrait: the class across, what is due and
                // unread side by side under it (stacked when one is empty).
                : !wide
                ? [...lead, ...lists]
                // Desktop direction A: the class on the left, what is due
                // and unread on the right.
                : [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: lead,
                          ),
                        ),
                        SizedBox(width: book ? Space.l * 2 : Space.xxl),
                        SizedBox(
                          // Up to the fold, less the page margin and half
                          // the gap.
                          width: book
                              ? width - fold!.at - pageMargin - Space.l
                              : paneWidth,
                          child: column([...dueList, ...unreadList]),
                        ),
                      ],
                    ),
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
    this.tone,
    this.onAttendance,
    this.cover = false,
  });

  /// On a flip phone's outer display: it fills the height it is given,
  /// with the count in large type and no badge (design/round-24 C).
  final bool cover;

  final _Slot slot;
  final String label, detail;
  final int minutes;

  /// Counting down to the start rather than to the end.
  final bool later;

  /// Lilac for today; another day's class reads apart in mint.
  final Tone? tone;

  /// Opens the attendance scanner; only while the class is on.
  final VoidCallback? onAttendance;

  @override
  Widget build(BuildContext context) {
    final tone = this.tone ?? context.tones.lilac;
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
          height: cover ? null : 226,
          child: Stack(
            children: [
              // The badge sits partly outside the card, as in the mockup,
              // centred behind the count below.
              if (!cover)
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
                right: cover ? Space.l : 20,
                bottom: cover ? Space.m : 26,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        color: cover ? tone.ink : tone.fill,
                        fontSize: cover ? 40 : 34,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      unit,
                      style: TextStyle(
                        color: cover ? tone.ink : tone.fill,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: cover
                    ? const EdgeInsets.all(Space.l)
                    : const EdgeInsets.fromLTRB(
                        Space.xl,
                        Space.xl,
                        120,
                        Space.xl,
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.m,
                        vertical: Space.xs,
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
                      maxLines: onAttendance == null ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tone.ink,
                        fontSize: cover ? 20 : 23,
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
                    if (onAttendance case final onTap?) ...[
                      const Spacer(),
                      Material(
                        color: tone.ink,
                        shape: const StadiumBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: onTap,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              Space.l,
                              Space.s,
                              Space.xl,
                              Space.s,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.qr_code_scanner,
                                  size: 18,
                                  color: tone.fill,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.takeAttendance,
                                  style: TextStyle(
                                    color: tone.fill,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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

/// The class after the hero's: name and room, its start on the right.
class _AfterCard extends StatelessWidget {
  const _AfterCard({required this.slot});

  final _Slot slot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Card(
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/courses/${slot.course.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.xl,
            Space.l,
            Space.xl,
            Space.l,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.nextClass,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.courseName(slot.course),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (slot.course.room case final room?)
                      Text(
                        room,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                clock(slot.session.start),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A list's name with its count in the list's colour, and 全部.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.title,
    required this.count,
    required this.color,
    required this.onAll,
  });

  final String title;
  final int count;
  final Color color;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 20, fontWeight: FontWeight.w900);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xs, Space.xl, 0, 2),
      child: Row(
        children: [
          Text(title, style: style),
          const SizedBox(width: 8),
          Text('$count', style: style.copyWith(color: color)),
          const Spacer(),
          TextButton(onPressed: onAll, child: Text(context.l10n.viewAll)),
        ],
      ),
    );
  }
}

/// One item under a group: a dot, its name, a line under it and maybe a
/// time on the right.
class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.dot,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Color dot;
  final String title, subtitle;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.xs,
          vertical: Space.m,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.xs, Space.s, Space.l, 0),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing case final t?)
              Padding(
                padding: const EdgeInsets.only(left: Space.m, top: 2),
                child: Text(
                  t,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A count and what it counts, for a flip phone's outer display.
class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.count,
    required this.label,
    required this.onTap,
  });

  final int count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
