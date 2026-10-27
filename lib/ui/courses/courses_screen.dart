import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../domain/models/course.dart';
import '../core/desk_list.dart';
import '../core/desktop_mode.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../../l10n/l10n.dart';
import '../today/desk_today.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String _query = '';

  /// The course shown beside the list on a desktop; the first until one
  /// is picked.
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    final desk = desktopUi(context) && listBeside(context);
    return Scaffold(
      extendBodyBehindAppBar: !desk,
      appBar: desk
          ? deskCrumbBar(
              context,
              parent: context.l10n.navTimetable,
              path: '/timetable',
              title: context.l10n.navCourses,
            )
          : subBar(context, context.l10n.navCourses),
      body: Loader<List<Course>>.watch(
        watch: () => repo.watch((repo) => repo.courses()),
        builder: (context, all) {
          final q = _query.toLowerCase();
          final shown = q.isEmpty
              ? all
              : all
                    .where(
                      (c) =>
                          c.fullName.toLowerCase().contains(q) ||
                          c.shortName.contains(q),
                    )
                    .toList();
          final semesters = <String, List<Course>>{};
          for (final c in shown) {
            semesters.putIfAbsent(c.semester, () => []).add(c);
          }
          if (desk) return _desk(context, shown, semesters);
          return ListView(
            padding: scrollPadding(context),
            children: [
              TextField(
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: context.l10n.searchCourses,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(child: Text(context.l10n.noMatchingCourses)),
                ),
              for (final entry in semesters.entries) ...[
                SectionLabel(semesterName(context, entry.key)),
                for (final c in entry.value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: rowGap),
                    child: _CourseBlock(course: c),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// design/round-25 課程: the search over every semester's courses, the
  /// picked one beside.
  Widget _desk(
    BuildContext context,
    List<Course> shown,
    Map<String, List<Course>> semesters,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final latest = semesters.keys.firstOrNull;
    final picked =
        shown.where((c) => c.id == _picked).firstOrNull ?? shown.firstOrNull;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: listWidthOf(context),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.l,
                  vertical: Space.m,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: scheme.outlineVariant),
                  ),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: context.l10n.searchCourses,
                    prefixIcon: const Icon(Icons.search, size: 16),
                  ),
                ),
              ),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(child: Text(context.l10n.noMatchingCourses)),
                ),
              for (final entry in semesters.entries) ...[
                DeskGroup(semesterName(context, entry.key)),
                for (final c in entry.value)
                  _DeskCourseRow(
                    course: c,
                    // Earlier semesters' courses step back.
                    past: entry.key != latest,
                    selected: c == picked,
                    onTap: () => setState(() => _picked = c.id),
                  ),
              ],
            ],
          ),
        ),
        VerticalDivider(width: 1, color: scheme.outlineVariant),
        Expanded(
          child: picked == null
              ? const SizedBox.shrink()
              : DeskCourse(
                  key: ValueKey(picked.id),
                  course: picked,
                  session: picked.sessions.firstOrNull,
                ),
        ),
      ],
    );
  }
}

/// A course in the desktop list: its first letter in its colour, its name
/// over when and where it meets.
class _DeskCourseRow extends StatelessWidget {
  const _DeskCourseRow({
    required this.course,
    required this.past,
    required this.selected,
    required this.onTap,
  });

  final Course course;
  final bool past, selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = context.tones.forCourse(course.id).strong;
    final name = context.courseName(course);
    return DeskRow(
      leading: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: past
              ? scheme.surfaceContainerHigh
              : color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          name.characters.firstOrNull ?? '',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: past ? scheme.onSurface : color,
          ),
        ),
      ),
      title: name,
      subtitle: _when(context, course),
      dimmed: past,
      selected: selected,
      onTap: onTap,
    );
  }
}

/// When and where a course meets, as `週三 3,4・週五 2・工學院 102`; null
/// when neither is known.
String? _when(BuildContext context, Course course) {
  final text = [
    for (final s in course.sessions)
      '${weekdayName(context, s.weekday)} ${s.periods.join(',')}',
    ?course.room,
  ].join('・');
  return text.isEmpty ? null : text;
}

class _CourseBlock extends StatelessWidget {
  const _CourseBlock({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.forCourse(course.id);
    final when = _when(context, course);
    return ToneBlock(
      tone: tone,
      padding: cardPadding,
      onTap: () => context.push('/courses/${course.id}'),
      child: Row(
        children: [
          CourseMark(courseId: course.id, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.courseName(course),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                if (when != null)
                  Text(
                    when,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
