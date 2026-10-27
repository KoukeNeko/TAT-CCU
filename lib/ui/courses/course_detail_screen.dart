import 'package:clock/clock.dart' as clk;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../domain/models/course.dart';
import '../core/desk_list.dart';
import '../core/desktop_mode.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../today/due_screen.dart';
import 'forum_screen.dart';
import 'module_screen.dart';
import '../../l10n/l10n.dart';

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
  List<Discussion> posts,
  List<GradeLine> grades,
  String? total,
  int sections,

  /// In the newest semester; an earlier one's has no next class.
  bool current,
});

/// Course page, variant D2-B (design/round-11): identity-colored hero card,
/// a row of summaries, upcoming work, then entries into the full lists.
class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({super.key, required this.courseId, this.open});

  final int courseId;

  /// The page open beside this one in a wide area; its row is lit, and
  /// another replaces it rather than stacking.
  final String? open;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return _Titled(
      builder: (context, titled) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _CourseBar(courseId: courseId, titled: titled),
        // The bar takes the course's name once the card's own name has
        // scrolled up under it, like an iOS large title.
        body: NotificationListener<ScrollUpdateNotification>(
          onNotification: (n) {
            if (n.depth == 0) titled.value = n.metrics.pixels > _nameScrolled;
            return false;
          },
          child: Loader<(Course?, _Summary)>.watch(
            watch: () => repo.watch((repo) async {
              final all = await repo.courses();
              final course = all.where((c) => c.id == courseId).firstOrNull;
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
                  current: course?.semester == all.firstOrNull?.semester,
                ),
              );
            }),
            builder: (context, data) {
              final (course, summary) = data;
              if (course == null) {
                return EmptyState(context.l10n.courseNotFound);
              }
              final tones = context.tones;
              final scheme = Theme.of(context).colorScheme;
              final base = '/courses/$courseId';
              void show(String path) =>
                  open != null ? context.go(path) : context.push(path);
              final firstDue = summary.due.firstOrNull;
              final cover = coverScreen(context);
              if (desktopUi(context) && !cover) {
                return _desk(context, course, summary, firstDue, show);
              }
              return ListView(
                padding: scrollPadding(context, top: cover ? Space.s : pageTop),
                children: [
                  if (!cover) ...[
                    _Hero(course: course, current: summary.current),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Stat(
                        tone: tones.peach,
                        value: firstDue == null
                            ? '0'
                            : timeLeft(context.l10n, firstDue.due),
                        label: firstDue == null
                            ? context.l10n.nothingDue
                            : context.l10n.nameDue(firstDue.name),
                        onTap: firstDue == null
                            ? null
                            : () => openDueItem(context, firstDue),
                      ),
                      const SizedBox(width: 8),
                      _Stat(
                        tone: tones.sun,
                        value: '${summary.posts.length}',
                        label: context.l10n.announcementsUnit,
                        onTap: () => show('$base/announcements'),
                      ),
                      const SizedBox(width: 8),
                      _Stat(
                        tone: Tone(
                          scheme.surfaceContainerHigh,
                          scheme.onSurface,
                          scheme.onSurfaceVariant,
                        ),
                        value: summary.total ?? '-',
                        label: context.l10n.currentGrade,
                        onTap: () => show('$base/grades'),
                      ),
                    ],
                  ),
                  if (summary.due.isNotEmpty) ...[
                    SectionLabel(context.l10n.toDo),
                    for (final d in summary.due)
                      Padding(
                        padding: const EdgeInsets.only(bottom: rowGap),
                        child: DueBlock(item: d),
                      ),
                  ],
                  SectionLabel(context.l10n.courseSection),
                  Card(
                    color: scheme.surfaceContainerLow,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _Entry(
                          selected: open == '$base/contents',
                          icon: Icons.folder_outlined,
                          title: context.l10n.allSections,
                          detail: context.l10n.sectionCount(summary.sections),
                          onTap: () => show('$base/contents'),
                        ),
                        _Entry(
                          selected: open == '$base/announcements',
                          icon: Icons.campaign_outlined,
                          title: context.l10n.announcements,
                          detail: context.l10n.postCount(summary.posts.length),
                          onTap: () => show('$base/announcements'),
                        ),
                        _Entry(
                          selected: open == '$base/grades',
                          icon: Icons.grading_outlined,
                          title: context.l10n.grades,
                          detail: context.l10n.itemCount(summary.grades.length),
                          onTap: () => show('$base/grades'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

extension on CourseDetailScreen {
  /// design/round-25: the course as a list column, its parts as rows that
  /// open beside it.
  Widget _desk(
    BuildContext context,
    Course course,
    _Summary summary,
    DueItem? firstDue,
    void Function(String path) show,
  ) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final tones = context.tones;
    final base = '/courses/$courseId';
    final next = summary.current
        ? nextClassLabel(course, clk.clock.now(), l10n)
        : null;
    final faint = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: scheme.onSurfaceVariant,
    );
    final tone = tones.forCourse(courseId);
    // A stat: the number large, what it counts small.
    Widget stat(String value, String label, VoidCallback? onTap, [Color? c]) =>
        DeskRow(
          leading: SizedBox(
            width: 58,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: c ?? scheme.onSurface,
              ),
            ),
          ),
          title: label,
          dimmed: true,
          onTap: onTap,
        );
    Widget part(String path, IconData icon, String title, String detail) =>
        DeskRow(
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 15, color: scheme.onSurfaceVariant),
          ),
          title: title,
          selected: open == path,
          trailing: Text('$detail  ›', style: faint.copyWith(fontSize: 11)),
          onTap: () => show(path),
        );
    // The page a due item opens, to light its row while it is open.
    String? pathOf(DueItem d) => switch (int.tryParse(
      Uri.tryParse(d.url ?? '')?.queryParameters['id'] ?? '',
    )) {
      final cmid? => '$base/modules/$cmid',
      null => null,
    };
    return ListView(
      padding: EdgeInsets.only(top: scrollPadding(context).top),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.l,
            Space.l,
            Space.l,
            Space.m,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: tone.strong,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: Space.s),
                  Expanded(
                    child: Text(
                      [?course.room, ...course.teachers.take(1)].join('・'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: faint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xs),
              Text(
                context.courseName(course),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              if (next != null) ...[
                const SizedBox(height: Space.s),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.s,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: tone.fill,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    l10n.nextClassAt(next),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: tone.ink,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        stat(
          firstDue == null ? '0' : timeLeft(l10n, firstDue.due),
          firstDue == null ? l10n.nothingDue : l10n.nameDue(firstDue.name),
          firstDue == null ? null : () => openDueItem(context, firstDue),
          tones.peach.strong,
        ),
        stat(
          l10n.postCount(summary.posts.length),
          l10n.announcements,
          () => show('$base/announcements'),
        ),
        stat(
          summary.total ?? '-',
          l10n.currentGrade,
          () => show('$base/grades'),
        ),
        if (summary.due.isNotEmpty) ...[
          DeskGroup(
            l10n.toDo,
            trailing: Text(l10n.itemCount(summary.due.length)),
          ),
          for (final d in summary.due)
            DeskRow(
              leading: SizedBox(
                width: 46,
                child: Text(
                  timeLeft(l10n, d.due),
                  style: faint.copyWith(
                    fontSize: 13,
                    color: d.due.difference(clk.clock.now()).inHours < 48
                        ? tones.peach.strong
                        : tones.sun.strong,
                  ),
                ),
              ),
              title: d.name,
              subtitle:
                  '${weekdayName(context, d.due.weekday)} '
                  '${monthDayTime(d.due)}',
              selected: open != null && open == pathOf(d),
              trailing: DeskStripe(tone.strong),
              onTap: () => openDueItem(context, d),
            ),
        ],
        DeskGroup(l10n.courseSection),
        part(
          '$base/contents',
          Icons.folder_outlined,
          l10n.allSections,
          l10n.sectionCount(summary.sections),
        ),
        part(
          '$base/announcements',
          Icons.campaign_outlined,
          l10n.announcements,
          l10n.postCount(summary.posts.length),
        ),
        part(
          '$base/grades',
          Icons.grading_outlined,
          l10n.grades,
          l10n.itemCount(summary.grades.length),
        ),
      ],
    );
  }
}

/// Time left until [due], in hours under a day.
String timeLeft(AppLocalizations l10n, DateTime due) {
  final left = due.difference(clk.clock.now());
  return left.inHours < 24
      ? l10n.hoursLeft(left.inHours)
      : l10n.daysLeft(left.inDays);
}

/// Next class from the timetable, e.g. `明天 10:10`; null without sessions.
String? nextClassLabel(Course course, DateTime now, AppLocalizations l10n) {
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
      0 => l10n.today,
      1 => l10n.tomorrow,
      _ => l10n.weekdayFull('${day.weekday}'),
    };
    return '$when ${clock(starts.first)}';
  }
  return null;
}

/// How far the page scrolls before the card's name has passed under the
/// app bar: the card's top inset and the name's line.
const _nameScrolled = Space.xl + 26;

/// Holds whether the page has scrolled past the card's name, for the bar.
class _Titled extends StatefulWidget {
  const _Titled({required this.builder});

  final Widget Function(BuildContext, ValueNotifier<bool>) builder;

  @override
  State<_Titled> createState() => _TitledState();
}

class _TitledState extends State<_Titled> {
  final _titled = ValueNotifier(false);

  @override
  void dispose() {
    _titled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _titled);
}

/// The glass app bar: the back button, and the course's name while
/// [titled].
class _CourseBar extends StatefulWidget implements PreferredSizeWidget {
  const _CourseBar({required this.courseId, required this.titled});

  final int courseId;
  final ValueListenable<bool> titled;

  @override
  // An AppBar's own, which the Scaffold sizes from the theme's bar height.
  Size get preferredSize => AppBar().preferredSize;

  @override
  State<_CourseBar> createState() => _CourseBarState();
}

class _CourseBarState extends State<_CourseBar> {
  // Shared with the page's own request while both are loading.
  late final _course = context.read<EcourseRepository>().courses().then(
    (all) => all.where((c) => c.id == widget.courseId).firstOrNull,
  );

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _course,
    builder: (context, snap) => ValueListenableBuilder(
      valueListenable: widget.titled,
      builder: (context, titled, _) {
        // A flip phone's outer display has no card with the name, so the
        // bar always shows it (design/round-24 flip-all).
        final shown = titled || coverScreen(context);
        // Beside its pages on a desktop, the path in their bar names it.
        if (desktopUi(context)) return subBar(context, '', back: false);
        return subBar(
          context,
          switch (snap.data) {
            final course? when shown => context.courseName(course),
            _ => '',
          },
          // Until then the back button floats on the page, bar-less.
          glass: shown,
        );
      },
    ),
  );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.course, required this.current});

  final Course course;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.forCourse(course.id);
    final next = current
        ? nextClassLabel(course, clk.clock.now(), context.l10n)
        : null;
    return Material(
      color: tone.fill,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(Corners.card)),
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
            padding: const EdgeInsets.fromLTRB(
              Space.xl,
              Space.xl,
              72,
              Space.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.courseName(course),
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
                        horizontal: Space.m,
                        vertical: Space.s,
                      ),
                      child: Text(
                        context.l10n.nextClassAt(next),
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
        radius: Corners.row,
        padding: const EdgeInsets.all(Space.m),
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
    this.selected = false,
  });

  final IconData icon;
  final String title, detail;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      tileColor: selected ? scheme.surfaceContainerHigh : null,
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
  contents,
  announcements,
  grades;

  String title(AppLocalizations l10n) => switch (this) {
    contents => l10n.allSections,
    announcements => l10n.announcements,
    grades => l10n.grades,
  };
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
  Widget build(BuildContext context) => switch (part) {
    // Contents builds its own app bar around the section shortcuts.
    CoursePart.contents => _Contents(courseId: courseId),
    CoursePart.announcements => _plain(
      context,
      _Announcements(courseId: courseId),
    ),
    CoursePart.grades => _plain(context, _Grades(courseId: courseId)),
  };

  Widget _plain(BuildContext context, Widget body) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: _partBar(context, courseId, part.title(context.l10n)),
    body: body,
  );
}

/// Every section in one continuous list, with a row of section shortcuts in
/// the app bar that follows the scroll (design/round-11, variant C2-A).
class _Contents extends StatelessWidget {
  const _Contents({required this.courseId});

  final int courseId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Loader<List<Section>>.watch(
      capsuleInBody: true,
      bar: (context) =>
          _partBar(context, courseId, CoursePart.contents.title(context.l10n)),
      watch: () => repo.watch((repo) => repo.contents(courseId)),
      builder: (context, sections) => sections.isEmpty
          ? Scaffold(
              appBar: _partBar(
                context,
                courseId,
                CoursePart.contents.title(context.l10n),
              ),
              body: CapsuleArea(child: EmptyState(context.l10n.noContents)),
            )
          : _SectionList(courseId: courseId, sections: sections),
    );
  }
}

class _SectionList extends StatefulWidget {
  const _SectionList({required this.courseId, required this.sections});

  final int courseId;
  final List<Section> sections;

  @override
  State<_SectionList> createState() => _SectionListState();
}

class _SectionListState extends State<_SectionList> {
  final _scroll = ScrollController();
  late final _headers = [for (final _ in widget.sections) GlobalKey()];
  late final _chips = [for (final _ in widget.sections) GlobalKey()];
  int _active = 0;

  /// Ignores scroll updates while a chip tap is animating to its section,
  /// so the highlight does not flick through every section on the way.
  bool _jumping = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_follow);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Top of the visible content: the glass app bar covers everything above.
  double get _barBottom => MediaQuery.paddingOf(context).top;

  double? _headerTop(int i) {
    final box = _headers[i].currentContext?.findRenderObject() as RenderBox?;
    return box?.localToGlobal(Offset.zero).dy;
  }

  void _follow() {
    if (_jumping) return;
    var active = 0;
    for (var i = 0; i < _headers.length; i++) {
      final top = _headerTop(i);
      if (top != null && top <= _barBottom + 24) active = i;
    }
    if (_scroll.position.extentAfter < 1) active = _headers.length - 1;
    _activate(active);
  }

  void _activate(int i) {
    if (i == _active) return;
    setState(() => _active = i);
    final chip = _chips[i].currentContext;
    if (chip != null) {
      Scrollable.ensureVisible(
        chip,
        alignment: 0.5,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutQuart,
      );
    }
  }

  Future<void> _jumpTo(int i) async {
    final top = _headerTop(i);
    if (top == null) return;
    _activate(i);
    _jumping = true;
    final target = (_scroll.offset + top - _barBottom - 4).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    await _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutQuart,
    );
    _jumping = false;
  }

  @override
  Widget build(BuildContext context) {
    final sections = widget.sections;
    final scheme = Theme.of(context).colorScheme;
    final course = context.tones.forCourse(widget.courseId);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _partBar(
        context,
        widget.courseId,
        CoursePart.contents.title(context.l10n),
        bottom: ChipBar(
          children: [
            for (final (i, s) in sections.indexed)
              KeyedSubtree(
                key: _chips[i],
                child: BarChip(
                  label: _sectionName(context, s),
                  selected: i == _active,
                  tone: course,
                  onTap: () => _jumpTo(i),
                ),
              ),
          ],
        ),
      ),
      body: CapsuleArea(
        child: Builder(
          builder: (context) => SingleChildScrollView(
            controller: _scroll,
            padding: desktopUi(context)
                ? EdgeInsets.fromLTRB(16, scrollPadding(context).top, 16, 32)
                : scrollPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, s) in sections.indexed) ...[
                  Padding(
                    key: _headers[i],
                    padding: const EdgeInsets.fromLTRB(
                      Space.xs,
                      Space.xl,
                      Space.xs,
                      Space.m,
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: _sectionName(context, s),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(
                            text:
                                '  ${context.l10n.itemCount(s.modules.length)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (desktopUi(context))
                    // Rows straight under their section, as in Mail.
                    for (final m in s.modules)
                      _ModuleRow(courseId: widget.courseId, module: m)
                  else
                    Card(
                      color: scheme.surfaceContainerLow,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (final (j, m) in s.modules.indexed) ...[
                            if (j > 0)
                              Divider(height: 1, color: scheme.outlineVariant),
                            _ModuleRow(courseId: widget.courseId, module: m),
                          ],
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A course part's bar: on a desktop the path from its course.
AppBar _partBar(
  BuildContext context,
  int courseId,
  String title, {
  PreferredSizeWidget? bottom,
}) => desktopUi(context)
    ? subBar(
        context,
        title,
        bottom: bottom,
        back: false,
        titleChild: CourseCrumbs(courseId: courseId, trail: [title]),
      )
    : subBar(context, title, bottom: bottom);

/// Moodle names the course-wide first section `General` in English.
String _sectionName(BuildContext context, Section s) =>
    s.name == 'General' ? context.l10n.sectionGeneral : s.name;

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.courseId, required this.module});

  final int courseId;
  final Module module;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    // Material types by function color; anything else stays neutral.
    final tone = switch (module.type) {
      'resource' || 'page' => tones.lilac,
      'assign' => tones.peach,
      'quiz' => tones.mint,
      'folder' => tones.sun,
      'url' => tones.identity[2],
      _ => Tone(
        scheme.surfaceContainerHigh,
        scheme.onSurface,
        scheme.onSurfaceVariant,
      ),
    };
    final due = module.due;
    final detail = due != null
        ? context.l10n.dueOn('${due.month}/${due.day}')
        : module.files.length > 1
        ? context.l10n.fileCount(module.files.length)
        : null;
    final overdue = due != null && due.isBefore(clk.clock.now());
    final path = modulePath(courseId, module);
    final open = path != null
        ? () => context.push(path, extra: module.name)
        : module.url == null
        ? null
        : () => openExternal(module.url!);
    if (desktopUi(context)) {
      return DeskRow(
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            _moduleIcons[module.type] ?? Icons.extension_outlined,
            size: 15,
            color: tone.strong,
          ),
        ),
        title: module.name,
        trailing: detail == null
            ? null
            : Text(
                detail,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: overdue
                      ? scheme.onSurfaceVariant
                      : due != null
                      ? tones.peach.strong
                      : scheme.onSurfaceVariant,
                ),
              ),
        onTap: open,
      );
    }
    return InkWell(
      onTap: path != null
          ? () => context.push(path, extra: module.name)
          : module.url == null
          ? null
          : () => openExternal(module.url!),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.l,
          vertical: Space.m,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tone.fill,
                borderRadius: BorderRadius.circular(Corners.small),
              ),
              child: Icon(
                _moduleIcons[module.type] ?? Icons.extension_outlined,
                size: 20,
                color: tone.ink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                module.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (detail != null) ...[
              const SizedBox(width: 8),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: due != null && !overdue
                      ? tones.peach.strong
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Announcements extends StatelessWidget {
  const _Announcements({required this.courseId});

  final int courseId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Loader<List<Discussion>>.watch(
      watch: () => repo.watch((repo) => repo.announcements(courseId)),
      builder: (context, posts) => posts.isEmpty
          ? EmptyState(context.l10n.noAnnouncements)
          : DiscussionList(courseId: courseId, discussions: posts),
    );
  }
}

class _Grades extends StatelessWidget {
  const _Grades({required this.courseId});

  final int courseId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Loader<List<GradeLine>>.watch(
      watch: () => repo.watch((repo) => repo.gradeItems(courseId)),
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
    if (lines.isEmpty) return EmptyState(context.l10n.noGradeItems);
    final scheme = Theme.of(context).colorScheme;
    if (desktopUi(context)) {
      return ListView(
        padding: EdgeInsets.fromLTRB(32, scrollPadding(context).top, 32, 32),
        children: [
          for (final l in lines)
            DeskLine(
              title: l.name,
              // Ungraded items repeat `-` (or `錯誤`) in both fields.
              detail: l.percent.isEmpty || l.percent == l.grade
                  ? null
                  : l.percent,
              value: l.grade,
            ),
        ],
      );
    }
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

/// The desktop UI's toolbar path for a page of a course (design/round-25):
/// the course, then [trail], the last being the page shown. The course
/// and 全部章節 lead back to their pages.
class CourseCrumbs extends StatelessWidget {
  const CourseCrumbs({super.key, required this.courseId, required this.trail});

  final int courseId;
  final List<String> trail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final muted = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    Widget link(String text, String path) => GestureDetector(
      onTap: () => context.go(path),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(text, style: muted),
      ),
    );
    final chevron = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(
        Icons.chevron_right,
        size: 16,
        color: scheme.onSurfaceVariant,
      ),
    );
    return CourseNameOf(
      courseId: courseId,
      builder: (context, name) => Row(
        children: [
          if (name != null) ...[link(name, '/courses/$courseId'), chevron],
          for (final (i, step) in trail.indexed) ...[
            if (i > 0) chevron,
            if (i < trail.length - 1)
              link(
                step,
                step == l10n.allSections
                    ? '/courses/$courseId/contents'
                    : '/courses/$courseId',
              )
            else
              Flexible(
                child: Text(
                  step,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// A course's name for pages that only know its id, from the saved answer
/// first; null until it is known.
class CourseNameOf extends StatefulWidget {
  const CourseNameOf({
    super.key,
    required this.courseId,
    required this.builder,
  });

  final int courseId;
  final Widget Function(BuildContext context, String? name) builder;

  @override
  State<CourseNameOf> createState() => _CourseNameOfState();
}

class _CourseNameOfState extends State<CourseNameOf> {
  late final _courses = context.read<EcourseRepository>().watch(
    (repo) => repo.courses(),
  );

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: _courses,
    builder: (context, snap) => widget.builder(context, switch ([
      for (final c in snap.data ?? const <Course>[])
        if (c.id == widget.courseId) c,
    ]) {
      [final c, ...] => context.courseName(c),
      _ => null,
    }),
  );
}
