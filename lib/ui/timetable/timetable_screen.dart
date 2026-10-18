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

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Scaffold(
      appBar: topBar('課表'),
      body: Loader<List<Course>>(
        load: () => repo.currentCourses(),
        builder: (context, courses) {
          final days = {
            for (final c in courses)
              for (final s in c.sessions) s.weekday,
          };
          final weekdays = [
            for (var d = 1; d <= 7; d++)
              if (d <= 5 || days.contains(d)) d,
          ];
          final slots = [
            for (final c in courses)
              for (final s in c.sessions)
                if (s.weekday == _day) (course: c, session: s),
          ]..sort((a, b) => a.session.start.compareTo(b.session.start));
          final theme = Theme.of(context);
          return ListView(
            padding: scrollPadding(context, top: 4),
            children: [
              Row(
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
              const SizedBox(height: 16),
              if (slots.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Text('這天沒有課', style: theme.textTheme.titleMedium),
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
                    child: Text(c.fullName, style: theme.textTheme.bodyMedium),
                  ),
              ],
            ],
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
