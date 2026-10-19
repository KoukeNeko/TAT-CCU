import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../domain/models/course.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../../l10n/l10n.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: topBar(context.l10n.navCourses),
      body: Loader<List<Course>>(
        load: () => repo.courses(),
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
          return ListView(
            padding: scrollPadding(context),
            children: [
              SearchBar(
                hintText: context.l10n.searchCourses,
                leading: const Icon(Icons.search),
                elevation: const WidgetStatePropertyAll(0),
                onChanged: (v) => setState(() => _query = v.trim()),
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
}

class _CourseBlock extends StatelessWidget {
  const _CourseBlock({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.forCourse(course.id);
    final when = [
      for (final s in course.sessions)
        '${weekdayName(context, s.weekday)} ${s.periods.join(',')}',
    ].join('・');
    return ToneBlock(
      tone: tone,
      padding: const EdgeInsets.all(14),
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
                if (when.isNotEmpty || course.room != null)
                  Text(
                    [
                      when,
                      course.room ?? '',
                    ].where((s) => s.isNotEmpty).join('・'),
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
