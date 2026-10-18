import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

/// Everything on the course page, loaded together so the summary renders in
/// one pass.
typedef _Summary = ({
  List<DueItem> due,
  List<Post> posts,
  List<GradeLine> grades,
  String? total,
  int sections,
});

/// Course page, variant D2-B (design/round-11): identity-colored hero card,
/// a row of summaries, upcoming work, then entries into the full lists.
class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final int courseId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Scaffold(
      body: Loader<(Course?, _Summary)>(
        load: () async {
          final course = (await repo.courses())
              .where((c) => c.id == courseId)
              .firstOrNull;
          final (due, posts, grades, totals, sections) = await (
            repo.dueSoon(days: 60),
            repo.announcements(courseId),
            repo.gradeItems(courseId),
            repo.gradeOverview(),
            repo.contents(courseId),
          ).wait;
          return (
            course,
            (
              due: due.where((d) => d.courseId == courseId).toList(),
              posts: posts,
              grades: grades,
              total: totals[courseId],
              sections: sections.length,
            ),
          );
        },
        builder: (context, data) {
          final (course, summary) = data;
          if (course == null) return const EmptyState('找不到這門課');
          final tones = context.tones;
          final scheme = Theme.of(context).colorScheme;
          final base = '/courses/$courseId';
          final firstDue = summary.due.firstOrNull;
          return ListView(
            padding: scrollPadding(context),
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: RoundBackButton(),
              ),
              const SizedBox(height: 12),
              _Hero(course: course),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Stat(
                    tone: tones.peach,
                    value: firstDue == null ? '0' : _left(firstDue.due),
                    label: firstDue == null ? '沒有待辦' : '${firstDue.name} 到期',
                  ),
                  const SizedBox(width: 8),
                  _Stat(
                    tone: tones.sun,
                    value: '${summary.posts.length}',
                    label: '則公告',
                    onTap: () => context.go('$base/announcements'),
                  ),
                  const SizedBox(width: 8),
                  _Stat(
                    tone: Tone(
                      scheme.surfaceContainerHigh,
                      scheme.onSurface,
                      scheme.onSurfaceVariant,
                    ),
                    value: summary.total ?? '-',
                    label: '目前成績',
                    onTap: () => context.go('$base/grades'),
                  ),
                ],
              ),
              if (summary.due.isNotEmpty) ...[
                const SectionLabel('待辦'),
                for (final d in summary.due)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DueBlock(item: d),
                  ),
              ],
              const SectionLabel('課程'),
              Card(
                color: scheme.surfaceContainerLow,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _Entry(
                      icon: Icons.folder_outlined,
                      title: '全部章節',
                      detail: '${summary.sections} 個章節',
                      onTap: () => context.go('$base/contents'),
                    ),
                    _Entry(
                      icon: Icons.campaign_outlined,
                      title: '公告',
                      detail: '${summary.posts.length} 則',
                      onTap: () => context.go('$base/announcements'),
                    ),
                    _Entry(
                      icon: Icons.grading_outlined,
                      title: '成績',
                      detail: '${summary.grades.length} 項',
                      onTap: () => context.go('$base/grades'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _left(DateTime due) {
  final left = due.difference(DateTime.now());
  return left.inHours < 24 ? '${left.inHours} 小時' : '${left.inDays} 天';
}

/// Next class from the timetable, e.g. `明天 10:10`; null without sessions.
String? nextClassLabel(Course course, DateTime now) {
  final minutes = now.hour * 60 + now.minute;
  for (var offset = 0; offset < 8; offset++) {
    final day = now.add(Duration(days: offset));
    final starts = [
      for (final s in course.sessions)
        if (s.weekday == day.weekday && (offset > 0 || s.start > minutes))
          s.start,
    ]..sort();
    if (starts.isEmpty) continue;
    final when = switch (offset) {
      0 => '今天',
      1 => '明天',
      _ => weekdayNames[day.weekday - 1],
    };
    return '$when ${clock(starts.first)}';
  }
  return null;
}

class _Hero extends StatelessWidget {
  const _Hero({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.forCourse(course.id);
    final next = nextClassLabel(course, DateTime.now());
    return Material(
      color: tone.fill,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -24,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: tone.strong,
                shape: courseShape(course.id),
              ),
              child: const SizedBox(width: 120, height: 120),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 72, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.fullName,
                  style: TextStyle(
                    color: tone.ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                if (course.room case final room?) ...[
                  const SizedBox(height: 8),
                  Text(
                    room,
                    style: TextStyle(
                      color: tone.ink.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (next != null) ...[
                  const SizedBox(height: 12),
                  DecoratedBox(
                    decoration: ShapeDecoration(
                      color: tone.strong,
                      shape: const StadiumBorder(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Text(
                        '下次上課　$next',
                        style: TextStyle(
                          color: tone.fill,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.tone,
    required this.value,
    required this.label,
    this.onTap,
  });

  final Tone tone;
  final String value, label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ToneBlock(
        tone: tone,
        radius: 22,
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title, detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: Text(
        detail,
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// One full list behind a course page entry.
enum CoursePart {
  contents('全部章節'),
  announcements('公告'),
  grades('成績');

  const CoursePart(this.title);

  final String title;
}

class CoursePartScreen extends StatelessWidget {
  const CoursePartScreen({
    super.key,
    required this.courseId,
    required this.part,
  });

  final int courseId;
  final CoursePart part;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, part.title),
      body: switch (part) {
        CoursePart.contents => _Contents(courseId: courseId),
        CoursePart.announcements => _Announcements(courseId: courseId),
        CoursePart.grades => _Grades(courseId: courseId),
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
          padding: scrollPadding(context),
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
      padding: scrollPadding(context),
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
            // Ungraded items repeat `-` (or `錯誤`) in both fields.
            subtitle: l.percent.isEmpty || l.percent == l.grade
                ? null
                : Text(l.percent),
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
