import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../domain/models/course.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../today/due_screen.dart';

const _moduleIcons = {
  'resource': Icons.description_outlined,
  'folder': Icons.folder_outlined,
  'url': Icons.link,
  'page': Icons.article_outlined,
  'assign': Icons.assignment_outlined,
  'quiz': Icons.quiz_outlined,
  'forum': Icons.forum_outlined,
  'attendance': Icons.how_to_reg_outlined,
};

class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final int courseId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Loader<Course?>(
      load: () async {
        final all = await repo.courses();
        return all.where((c) => c.id == courseId).firstOrNull;
      },
      builder: (context, course) {
        if (course == null) {
          return const Scaffold(body: Center(child: Text('找不到這門課')));
        }
        final tone = context.tones.forCourse(course.id);
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: tone.fill,
              foregroundColor: tone.ink,
              automaticallyImplyLeading: false,
              toolbarHeight: 148,
              titleSpacing: 16,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RoundBackButton(
                    color: Colors.white.withValues(alpha: 0.35),
                    iconColor: tone.ink,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CourseMark(courseId: course.id, size: 52),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.fullName,
                              maxLines: 3,
                              style: TextStyle(
                                color: tone.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                height: 1.25,
                              ),
                            ),
                            Text(
                              [
                                course.room ?? '',
                                for (final s in course.sessions)
                                  '${weekdayNames[s.weekday - 1]} ${clock(s.start)}–${clock(s.end)}',
                              ].where((s) => s.isNotEmpty).join('・'),
                              style: TextStyle(
                                color: tone.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                labelColor: tone.ink,
                unselectedLabelColor: tone.ink.withValues(alpha: 0.6),
                indicatorColor: tone.strong,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '內容'),
                  Tab(text: '待辦'),
                  Tab(text: '公告'),
                  Tab(text: '成績'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _Contents(courseId: course.id),
                _Due(courseId: course.id),
                _Announcements(courseId: course.id),
                _Grades(courseId: course.id),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Contents extends StatelessWidget {
  const _Contents({required this.courseId});

  final int courseId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    final scheme = Theme.of(context).colorScheme;
    return Loader<List<Section>>(
      load: () => repo.contents(courseId),
      builder: (context, sections) {
        if (sections.isEmpty) return const EmptyState('還沒有課程內容');
        return ListView(
          padding: scrollPadding(context, top: 0),
          children: [
            for (final s in sections) ...[
              SectionLabel(s.name),
              Card(
                color: scheme.surfaceContainerLow,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final m in s.modules)
                      ListTile(
                        leading: Icon(
                          _moduleIcons[m.type] ?? Icons.extension_outlined,
                        ),
                        title: Text(
                          m.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onTap: m.url == null
                            ? null
                            : () => openExternal(m.url!),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Due extends StatelessWidget {
  const _Due({required this.courseId});

  final int courseId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Loader<List<DueItem>>(
      load: () async =>
          (await repo.dueSoon(days: 60))
              .where((d) => d.courseId == courseId)
              .toList(),
      builder: (context, items) {
        if (items.isEmpty) return const EmptyState('沒有待辦');
        return ListView.separated(
          padding: scrollPadding(context, top: 16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => DueBlock(item: items[i]),
        );
      },
    );
  }
}

class _Announcements extends StatelessWidget {
  const _Announcements({required this.courseId});

  final int courseId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    final scheme = Theme.of(context).colorScheme;
    return Loader<List<Post>>(
      load: () => repo.announcements(courseId),
      builder: (context, posts) {
        if (posts.isEmpty) return const EmptyState('沒有公告');
        return ListView.separated(
          padding: scrollPadding(context, top: 16),
          itemCount: posts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final p = posts[i];
            return Card(
              color: scheme.surfaceContainerLow,
              child: ExpansionTile(
                shape: const Border(),
                title: Text(
                  p.subject,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('${p.author}・${dateTimeLabel(p.time)}'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedAlignment: Alignment.topLeft,
                children: [Text(p.body)],
              ),
            );
          },
        );
      },
    );
  }
}

class _Grades extends StatelessWidget {
  const _Grades({required this.courseId});

  final int courseId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Loader<List<GradeLine>>(
      load: () => repo.gradeItems(courseId),
      builder: (context, lines) => GradeList(lines: lines),
    );
  }
}

/// Shared by the course tab and the grades screen.
class GradeList extends StatelessWidget {
  const GradeList({super.key, required this.lines});

  final List<GradeLine> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const EmptyState('還沒有成績項目');
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: scrollPadding(context, top: 16),
      itemCount: lines.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final l = lines[i];
        return Card(
          color: scheme.surfaceContainerLow,
          child: ListTile(
            title: Text(
              l.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: l.percent.isEmpty ? null : Text(l.percent),
            trailing: Text(
              l.grade,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        );
      },
    );
  }
}
