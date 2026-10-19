import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../domain/models/course.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../../l10n/l10n.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  int _day = DateTime.now().weekday;

  /// Chosen semester; null follows the newest one.
  String? _semester;

  /// One page per weekday shown; rebuilt when the semester changes.
  PageController? _pages;

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  void _pickSemester(String semester) {
    _pages?.dispose();
    setState(() {
      _semester = semester;
      _pages = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Scaffold(
      body: Loader<List<Course>>.watch(
        watch: () => repo.watch((repo) => repo.courses()),
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
          // A weekend day without classes falls back to the last day shown.
          final page = weekdays.contains(_day)
              ? weekdays.indexOf(_day)
              : weekdays.length - 1;
          final pages = _pages ??= PageController(initialPage: page);
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: topBar(
              context.l10n.navTimetable,
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
                      onSelected: _pickSemester,
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
                      for (final (i, d) in weekdays.indexed)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: _DayPill(
                              label: weekdayShort(context, d),
                              selected: i == page,
                              busy: days.contains(d),
                              onTap: () => pages.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 420),
                                curve: Curves.easeOutQuart,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            body: Builder(
              builder: (context) => PageView(
                controller: pages,
                onPageChanged: (i) => setState(() => _day = weekdays[i]),
                children: [
                  for (final d in weekdays) _dayList(context, courses, d),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _dayList(BuildContext context, List<Course> courses, int day) {
  final slots = [
    for (final c in courses)
      for (final s in c.sessions)
        if (s.weekday == day) (course: c, session: s),
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
              context.l10n.noClassesThisDay,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
      for (final s in slots)
        Padding(
          padding: const EdgeInsets.only(bottom: rowGap),
          child: _ClassBlock(
            course: s.course,
            start: s.session.start,
            end: s.session.end,
            periods: s.session.periods,
          ),
        ),
      if (courses.any((c) => c.sessions.isEmpty)) ...[
        SectionLabel(context.l10n.unscheduled),
        for (final c in courses.where((c) => c.sessions.isEmpty))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(c.fullName, style: theme.textTheme.bodyMedium),
          ),
      ],
    ],
  );
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
      onTap: () => context.push('/courses/${course.id}'),
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

/// App bar capsule showing the semester being viewed; opens a glass list of
/// every semester with its course count (design/round-11, variant M1).
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

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final picked = await showGlassMenu<String>(
      context,
      anchor: box.localToGlobal(Offset.zero) & box.size,
      selected: selected,
      items: [
        for (final s in semesters)
          (
            value: s,
            title: semesterName(context, s),
            detail: context.l10n.courseCount(counts[s] ?? 0),
            icon: null,
            tone: null,
          ),
      ],
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.lilac;
    return Semantics(
      button: true,
      label: context.l10n.switchSemester,
      child: Material(
        color: tone.fill,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => _open(context),
          child: Container(
            height: 40,
            padding: const EdgeInsets.only(left: 14, right: 8),
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
        ),
      ),
    );
  }
}
