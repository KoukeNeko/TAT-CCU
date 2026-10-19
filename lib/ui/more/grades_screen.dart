import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../domain/models/course.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../../l10n/l10n.dart';
import '../core/campus_web_screen.dart';
import 'portal_screen.dart';

/// 本學期: eCourse2 running grades per course. 歷年: the semester grades in
/// 成績查詢, still the school's website.
class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  var _history = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = context.read<EcourseRepository>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(
        context,
        l10n.grades,
        action: const SchoolSiteButton('0007'),
        bottom: ChipBar(
          children: [
            BarChip(
              label: l10n.gradesThisTerm,
              selected: !_history,
              onTap: () => setState(() => _history = false),
            ),
            BarChip(
              label: l10n.gradesHistory,
              selected: _history,
              onTap: () => setState(() => _history = true),
            ),
          ],
        ),
      ),
      body: _history
          ? _historyBody(context)
          : Loader<(List<Course>, Map<int, String>)>(
              load: () async =>
                  (await repo.courses(), await repo.gradeOverview()),
              builder: (context, data) {
                final (courses, grades) = data;
                final graded = courses
                    .where((c) => grades.containsKey(c.id))
                    .toList();
                if (graded.isEmpty) return EmptyState(context.l10n.noGrades);
                final tones = context.tones;
                return ListView.separated(
                  padding: scrollPadding(context),
                  itemCount: graded.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final c = graded[i];
                    final tone = tones.forCourse(c.id);
                    return ToneBlock(
                      tone: tone,
                      padding: const EdgeInsets.all(14),
                      onTap: () => context.push('/courses/${c.id}'),
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

  // shortcut: 成績查詢 has not been read natively yet, so 歷年 opens the
  // website; parse its pages once they are probed.
  Widget _historyBody(BuildContext context) {
    final system = campusSystems['0007']!;
    return Center(
      child: FilledButton.tonalIcon(
        onPressed: () => openCampusPage(context, entryUrl(system), system.name),
        icon: const Icon(Icons.north_east, size: 18),
        label: Text(context.l10n.gradesOnSchoolSite),
      ),
    );
  }
}
