import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../domain/models/course.dart';
import '../../domain/models/timetable.dart';
import '../../l10n/l10n.dart';
import '../core/desk_list.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../courses/course_detail_screen.dart';
import '../notifications/notifications_screen.dart';
import 'due_screen.dart';

typedef DeskSlot = ({Course course, ClassSession session});

/// 首頁 in the desktop UI (design/round-25): today's classes, what is due
/// and what is unread in a list, the picked class's course beside it.
class DeskToday extends StatefulWidget {
  const DeskToday({
    super.key,
    required this.headline,
    required this.slots,
    required this.hero,
    required this.after,
    required this.minute,
    required this.due,
    required this.latest,
    required this.unread,
  });

  final String headline;

  /// Today's classes, in order; or the next school day's first.
  final List<DeskSlot> slots;

  /// The class on now or next, lit until another is picked.
  final DeskSlot? hero;

  /// The class after [hero] today.
  final DeskSlot? after;

  /// Minutes after midnight now.
  final int minute;
  final List<DueItem> due;
  final List<NoticeItem> latest;
  final int unread;

  @override
  State<DeskToday> createState() => _DeskTodayState();
}

class _DeskTodayState extends State<DeskToday> {
  DeskSlot? _picked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final picked = _picked ?? widget.hero ?? widget.slots.firstOrNull;
    final courses = {for (final s in widget.slots) s.course.id: s.course};
    final faint = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: scheme.onSurfaceVariant,
    );
    final list = ListView(
      padding: EdgeInsets.zero,
      children: [
        DeskGroup(
          widget.headline,
          trailing: Text(
            '${weekdayName(context, now.weekday)} ${monthDay(now)}',
          ),
        ),
        for (final s in widget.slots)
          DeskRow(
            leading: SizedBox(
              width: 46,
              child: Text(
                '${clock(s.session.start)}\n${clock(s.session.end)}',
                style: faint.copyWith(height: 1.25),
              ),
            ),
            title: context.courseName(s.course),
            subtitle: s.course.room,
            selected: s == picked,
            dimmed: s.session.end <= widget.minute,
            trailing: s == widget.hero && s.session.start <= widget.minute
                ? DeskTag(l10n.inClass)
                : s.session.end <= widget.minute
                ? null
                : DeskStripe(tones.forCourse(s.course.id).strong),
            onTap: () => setState(() => _picked = s),
          ),
        if (widget.due.isNotEmpty) ...[
          DeskGroup(
            l10n.dueThisWeek,
            trailing: GestureDetector(
              onTap: () => context.push('/today/due'),
              child: Text(
                '${widget.due.length}',
                style: TextStyle(color: scheme.primary),
              ),
            ),
          ),
          for (final item in widget.due)
            DeskRow(
              leading: SizedBox(
                width: 46,
                child: Text(
                  timeLeft(l10n, item.due),
                  style: faint.copyWith(
                    // Within two days, as on the due page.
                    color: item.due.difference(now).inHours < 48
                        ? tones.peach.strong
                        : tones.sun.strong,
                  ),
                ),
              ),
              title: item.name,
              subtitle:
                  '${switch (courses[item.courseId]) {
                    final c? => context.courseName(c),
                    null => context.courseNameOf(item.course),
                  }}・${weekdayName(context, item.due.weekday)} '
                  '${clock(item.due.hour * 60 + item.due.minute)}',
              trailing: DeskStripe(tones.forCourse(item.courseId).strong),
              onTap: item.url == null ? null : () => openDueItem(context, item),
            ),
        ],
        if (widget.unread > 0) ...[
          DeskGroup(l10n.unread, trailing: Text('${widget.unread}')),
          for (final n in widget.latest)
            DeskRow(
              leading: Icon(
                Icons.forum_outlined,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
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
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: paneWidth,
          child: ColoredBox(color: scheme.surfaceContainerLowest, child: list),
        ),
        VerticalDivider(width: 1, color: scheme.outlineVariant),
        Expanded(
          child: picked == null
              ? const SizedBox.shrink()
              : _CourseBeside(
                  key: ValueKey(picked.course.id),
                  slot: picked,
                  minute: widget.minute,
                  live: picked == widget.hero,
                  after: picked == widget.hero ? widget.after : null,
                ),
        ),
      ],
    );
  }
}

/// The picked class's course: its time, the latest announcements and the
/// grades so far.
class _CourseBeside extends StatefulWidget {
  const _CourseBeside({
    super.key,
    required this.slot,
    required this.minute,
    required this.live,
    required this.after,
  });

  final DeskSlot slot;
  final int minute;

  /// The class on now or next, which counts down.
  final bool live;
  final DeskSlot? after;

  @override
  State<_CourseBeside> createState() => _CourseBesideState();
}

class _CourseBesideState extends State<_CourseBeside> {
  late final Future<(List<Discussion>, List<GradeLine>)> _data = () async {
    final repo = context.read<EcourseRepository>();
    final id = widget.slot.course.id;
    return (await repo.announcements(id), await repo.gradeItems(id));
  }();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final tone = context.tones.forCourse(widget.slot.course.id);
    final course = widget.slot.course;
    final session = widget.slot.session;
    final on = widget.live && session.start <= widget.minute;
    final muted = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 26, 32, 32),
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: tone.strong,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: Space.s),
            Text(l10n.navCourses, style: muted.copyWith(fontSize: 12)),
          ],
        ),
        const SizedBox(height: Space.s),
        Text(
          context.courseName(course),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.l,
          children: [
            if (course.room case final room?) Text(room, style: muted),
            if (course.teachers.isNotEmpty)
              Text(course.teachers.first, style: muted),
            Text('${clock(session.start)}–${clock(session.end)}', style: muted),
          ],
        ),
        if (widget.live) ...[
          const SizedBox(height: Space.xl),
          DeskCountdown(
            color: tone.strong,
            minutes: on
                ? session.end - widget.minute
                : session.start - widget.minute,
            done: on
                ? (widget.minute - session.start) /
                      math.max(1, session.end - session.start)
                : 0,
            title: on
                ? '${l10n.inClass}・${l10n.untilTime(clock(session.end))}'
                : '${l10n.nextClass}・${l10n.startsAt(clock(session.start))}',
            detail: switch (widget.after) {
              final a? =>
                '${l10n.nextClass} ${clock(a.session.start)} '
                    '${context.courseName(a.course)}${a.course.room == null ? '' : '・${a.course.room}'}',
              null => null,
            },
            action: DeskButton(
              icon: Icons.menu_book_outlined,
              label: l10n.openCourse,
              primary: true,
              onPressed: () => context.go('/courses/${course.id}'),
            ),
          ),
        ] else ...[
          const SizedBox(height: Space.l),
          Align(
            alignment: Alignment.centerLeft,
            child: DeskButton(
              icon: Icons.menu_book_outlined,
              label: l10n.openCourse,
              primary: true,
              onPressed: () => context.go('/courses/${course.id}'),
            ),
          ),
        ],
        const SizedBox(height: Space.xxl),
        FutureBuilder(
          future: _data,
          builder: (context, snap) {
            final (posts, grades) =
                snap.data ?? (const <Discussion>[], const <GradeLine>[]);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (posts.isNotEmpty) ...[
                  Expanded(
                    child: DeskSection(
                      title: l10n.announcements,
                      action: posts.isEmpty
                          ? null
                          : l10n.postCount(posts.length),
                      onAction: () =>
                          context.go('/courses/${course.id}/announcements'),
                      children: [
                        for (final p in posts.take(4))
                          DeskLine(
                            title: p.subject,
                            detail: '${p.author}・${monthDay(p.time)}',
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 28),
                ],
                Expanded(
                  child: DeskSection(
                    title: l10n.grades,
                    action: grades.isEmpty
                        ? null
                        : l10n.itemCount(grades.length),
                    onAction: () => context.go('/courses/${course.id}/grades'),
                    children: [
                      for (final g in grades.take(5))
                        DeskLine(
                          title: g.name,
                          detail: g.percent.isEmpty || g.percent == '-'
                              ? null
                              : g.percent,
                          value: g.grade,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
