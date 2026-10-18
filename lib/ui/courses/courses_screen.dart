import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../domain/models/course.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

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
      appBar: topBar('課程'),
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
                hintText: '搜尋課程',
                leading: const Icon(Icons.search),
                elevation: const WidgetStatePropertyAll(0),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: Text('沒有符合的課程')),
                ),
              for (final entry in semesters.entries) ...[
                SectionLabel(_semesterLabel(entry.key)),
                for (final c in entry.value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
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

/// `115_1` → `115 學年上學期`.
String _semesterLabel(String semester) {
  final parts = semester.split('_');
  if (parts.length < 2) return semester;
  final term = switch (parts[1]) {
    '1' => '上學期',
    '2' => '下學期',
    _ => '暑期',
  };
  return '${parts[0]} 學年$term';
}

class _CourseBlock extends StatelessWidget {
  const _CourseBlock({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.forCourse(course.id);
    final when = [
      for (final s in course.sessions)
        '${weekdayNames[s.weekday - 1]} ${s.periods.join(',')}',
    ].join('・');
    return ToneBlock(
      tone: tone,
      padding: const EdgeInsets.all(14),
      onTap: () => context.go('/courses/${course.id}'),
      child: Row(
        children: [
          CourseMark(courseId: course.id, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.fullName,
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
