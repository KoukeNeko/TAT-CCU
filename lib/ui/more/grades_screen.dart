import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../domain/models/course.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// eCourse2 running grades per course. Final semester grades live in the
/// school's grade system, reachable from 校務系統.
class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Scaffold(
      appBar: subBar(context, '成績'),
      body: Loader<(List<Course>, Map<int, String>)>(
        load: () async => (await repo.courses(), await repo.gradeOverview()),
        builder: (context, data) {
          final (courses, grades) = data;
          final graded = courses
              .where((c) => grades.containsKey(c.id))
              .toList();
          if (graded.isEmpty) return const EmptyState('還沒有成績');
          final tones = context.tones;
          return ListView.separated(
            padding: scrollPadding(context, top: 16),
            itemCount: graded.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final c = graded[i];
              final tone = tones.forCourse(c.id);
              return ToneBlock(
                tone: tone,
                padding: const EdgeInsets.all(14),
                onTap: () => context.go('/courses/${c.id}'),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              height: 1.25,
                            ),
                          ),
                          Text(
                            c.semester,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    CookieBadge(
                      value: grades[c.id]!,
                      color: tone.strong,
                      ink: tone.fill,
                      size: 72,
                      shape: courseShape(c.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
