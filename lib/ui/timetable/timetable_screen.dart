import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../domain/models/course.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  int _day = DateTime.now().weekday;

  /// Chosen semester; null follows the newest one.
  String? _semester;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Scaffold(
      body: Loader<List<Course>>(
        load: () => repo.courses(),
        builder: (context, all) {
          // Courses come newest first; a set keeps that order.
          final semesters = {for (final c in all) c.semester}.toList();
          final semester =
              _semester ?? (semesters.isEmpty ? '' : semesters.first);
          final courses = all.where((c) => c.semester == semester).toList();
          final days = {
            for (final c in courses)
              for (final s in c.sessions) s.weekday,
          };
          final weekdays = [
            for (var d = 1; d <= 7; d++)
              if (d <= 5 || days.contains(d)) d,
          ];
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: topBar(
              '課表',
              actions: [
                if (semesters.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _SemesterMenu(
                      semesters: semesters,
                      selected: semester,
                      counts: {
                        for (final s in semesters)
                          s: all.where((c) => c.semester == s).length,
                      },
                      onSelected: (s) => setState(() => _semester = s),
                    ),
                  ),
              ],
              // Days stay pinned in the glass bar while classes scroll.
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 0, 13, 10),
                  child: Row(
                    children: [
                      for (final d in weekdays)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: _DayPill(
                              label: weekdayNames[d - 1].substring(1),
                              selected: d == _day,
                              busy: days.contains(d),
                              onTap: () => setState(() => _day = d),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            body: Builder(
              builder: (context) {
                final slots = [
                  for (final c in courses)
                    for (final s in c.sessions)
                      if (s.weekday == _day) (course: c, session: s),
                ]..sort((a, b) => a.session.start.compareTo(b.session.start));
                final theme = Theme.of(context);
                return ListView(
                  padding: scrollPadding(context),
                  children: [
                    if (slots.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Center(
                          child: Text(
                            '這天沒有課',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ),
                    for (final s in slots)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ClassBlock(
                          course: s.course,
                          start: s.session.start,
                          end: s.session.end,
                          periods: s.session.periods,
                        ),
                      ),
                    if (courses.any((c) => c.sessions.isEmpty)) ...[
                      const SectionLabel('未排時間'),
                      for (final c in courses.where((c) => c.sessions.isEmpty))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            c.fullName,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.label,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool selected, busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = context.tones.lilac;
    return Material(
      color: selected ? tone.strong : scheme.surfaceContainerHigh,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: selected ? tone.fill : scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: busy
                      ? (selected ? tone.fill : tone.strong)
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassBlock extends StatelessWidget {
  const _ClassBlock({
    required this.course,
    required this.start,
    required this.end,
    required this.periods,
  });

  final Course course;
  final int start, end;
  final List<String> periods;

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.forCourse(course.id);
    // Height follows class length so a 3-hour block reads as long.
    final height = (end - start) * 0.9 + 40;
    return ToneBlock(
      tone: tone,
      onTap: () => context.go('/courses/${course.id}'),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clock(start),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  clock(end),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.room ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            CookieBadge(
              value: periods.join(),
              color: tone.strong,
              ink: tone.fill,
              size: 52,
              shape: courseShape(course.id),
            ),
          ],
        ),
      ),
    );
  }
}

/// App bar capsule showing the semester being viewed; opens a menu of every
/// semester with its course count (design/round-10, variant A).
class _SemesterMenu extends StatelessWidget {
  const _SemesterMenu({
    required this.semesters,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final List<String> semesters;
  final String selected;
  final Map<String, int> counts;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.lilac;
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      tooltip: '切換學期',
      initialValue: selected,
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      // Keeps the pressed-item highlight inside the rounded corners.
      clipBehavior: Clip.antiAlias,
      offset: const Offset(0, 8),
      color: scheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      itemBuilder: (context) => [
        for (final s in semesters)
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    semesterLabel(s),
                    style: TextStyle(
                      fontWeight: s == selected
                          ? FontWeight.w900
                          : FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${counts[s]} 門課',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: s == selected
                      ? Icon(Icons.check, size: 18, color: tone.strong)
                      : null,
                ),
              ],
            ),
          ),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.only(left: 14, right: 8),
        decoration: ShapeDecoration(
          color: tone.fill,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              semesterShort(selected),
              style: TextStyle(
                color: tone.ink,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: tone.ink),
          ],
        ),
      ),
    );
  }
}
