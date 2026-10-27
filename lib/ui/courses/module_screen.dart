import 'package:clock/clock.dart' as clk;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../core/desk_list.dart';
import '../core/desktop_mode.dart';
import '../core/compose_screen.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../../l10n/l10n.dart';
import 'course_detail_screen.dart';
import 'forum_screen.dart';
import '../core/campus_web_screen.dart';
import '../core/glass_dialog.dart';
import '../core/pdf_viewer.dart';

/// Module types with a page of their own; others open on eCourse2.
const moduleTypesWithPage = {'assign', 'quiz', 'folder', 'resource', 'forum'};

/// Where [m] opens in the app, or null when only eCourse2's page has it.
String? modulePath(int courseId, Module m) => switch (m.type) {
  'attendance' => '/courses/$courseId/attendance/${m.id}',
  'absenceform' => '/courses/$courseId/absence/${m.id}',
  _ when moduleTypesWithPage.contains(m.type) =>
    '/courses/$courseId/modules/${m.id}',
  _ => null,
};

/// One assignment, quiz or file collection (design/round-11, variant B1):
/// a horizontal progress card for timed work, then files and description.
class ModuleScreen extends StatelessWidget {
  const ModuleScreen({
    super.key,
    required this.courseId,
    required this.cmid,
    this.title,
  });

  final int courseId, cmid;

  /// The module's name when the opener knows it; shown while loading.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Loader<Module?>.watch(
      capsuleInBody: true,
      bar: (context) => subBar(context, title ?? ''),
      watch: () => repo.watch(
        (repo) async =>
            [for (final s in await repo.contents(courseId)) ...s.modules]
                .where((m) => m.id == cmid)
                .firstOrNull,
      ),
      builder: (context, module) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: desktopUi(context)
            ? subBar(
                context,
                module?.name ?? '',
                back: false,
                titleChild: CourseCrumbs(
                  courseId: courseId,
                  trail: [context.l10n.allSections, module?.name ?? ''],
                ),
              )
            : subBar(context, module?.name ?? ''),
        body: CapsuleArea(
          child: switch (module?.type) {
            null => EmptyState(context.l10n.itemNotFound),
            'assign' => Loader<Assignment>.watch(
              watch: () => repo.watch(
                (repo) => repo.assignment(courseId, module!.instance),
              ),
              builder: (context, a) => _AssignmentBody(
                assignment: a,
                cmid: cmid,
                courseId: courseId,
                module: module!,
              ),
            ),
            'forum' => ForumBody(courseId: courseId, forumId: module!.instance),
            'quiz' => Loader<Quiz>.watch(
              watch: () =>
                  repo.watch((repo) => repo.quiz(courseId, module!.instance)),
              builder: (context, q) => _QuizBody(
                quiz: q,
                courseId: courseId,
                module: module!,
                // Taken on eCourse2, signed in through the campus web view.
                onOpen: module.url == null
                    ? null
                    : () => openCampusPage(context, module.url!, module.name),
              ),
            ),
            _ => _FilesBody(files: module!.files),
          },
        ),
      ),
    );
  }
}

class _AssignmentBody extends StatelessWidget {
  const _AssignmentBody({
    required this.assignment,
    required this.cmid,
    required this.courseId,
    required this.module,
  });

  final Assignment assignment;
  final int cmid, courseId;
  final Module module;

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    final l10n = context.l10n;
    final now = clk.clock.now();
    final progress = _Progress(
      steps: [
        (
          l10n.stepOpens,
          a.opens == null ? '—' : monthDay(a.opens!),
          a.opens?.isBefore(now) ?? true,
        ),
        (
          l10n.stepSubmitted,
          a.submittedAt == null ? l10n.notSubmitted : monthDay(a.submittedAt!),
          a.submittedAt != null,
        ),
        (
          l10n.stepDue,
          a.due == null ? '—' : monthDay(a.due!),
          a.due?.isBefore(now) ?? false,
        ),
        (l10n.stepGrade, a.grade ?? '—', a.grade != null),
      ],
    );
    final work = [
      if (a.submission.isNotEmpty) ...[
        SectionLabel(l10n.mySubmission),
        FileList(files: a.submission, detail: (f) => monthDayTime(f.modified)),
      ] else if (desktopUi(context)) ...[
        SectionLabel(l10n.mySubmission),
        const SizedBox(height: Space.m),
        _Unsubmitted(label: l10n.notSubmitted),
      ],
      if (a.intro.isNotEmpty) ...[
        SectionLabel(l10n.description),
        _Text(a.intro),
      ],
      if (a.attachments.isNotEmpty) ...[
        SectionLabel(l10n.attachments),
        FileList(files: a.attachments, detail: (f) => fileSize(f.size)),
      ],
    ];
    final comments = [
      if (a.commentsOn case final submission?)
        _Comments(cmid: cmid, submission: submission),
    ];
    if (desktopUi(context)) {
      final due = a.due;
      return _DeskModule(
        courseId: courseId,
        module: module,
        meta: [
          if (due != null)
            (
              [
                l10n.dueOn(dateTimeLabel(context, due)),
                if (due.isAfter(now)) timeLeft(l10n, due),
              ].join('・'),
              a.submittedAt == null ? context.tones.peach.strong : null,
            ),
          (
            a.submittedAt == null
                ? l10n.notSubmitted
                : '${l10n.stepSubmitted} ${monthDay(a.submittedAt!)}',
            null,
          ),
        ],
        progress: progress,
        left: work,
        right: comments,
      );
    }
    return ListView(
      padding: scrollPadding(context),
      children: [progress, ...work, ...comments],
    );
  }
}

/// Where the submitted files go before there are any.
class _Unsubmitted extends StatelessWidget {
  const _Unsubmitted({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// design/round-25: a module in the desktop UI. Its course and kind over
/// the name, when it closes and where it stands, the way to eCourse2, the
/// four steps as bars, then two columns.
class _DeskModule extends StatelessWidget {
  const _DeskModule({
    required this.courseId,
    required this.module,
    required this.meta,
    required this.progress,
    required this.left,
    required this.right,
  });

  final int courseId;
  final Module module;

  /// Short facts after the name, each in its own colour or muted.
  final List<(String, Color?)> meta;
  final Widget progress;
  final List<Widget> left, right;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    final url = module.url;
    return ListView(
      padding: scrollPadding(context),
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: context.tones.forCourse(courseId).strong,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: Space.s),
            Expanded(
              child: CourseNameOf(
                courseId: courseId,
                builder: (context, name) => Text(
                  [?name, l10n.eventLabel(module.type, '')].join('・'),
                  style: muted.copyWith(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.s),
        SelectableText(
          module.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.m,
          children: [
            for (final (text, color) in meta)
              Text(text, style: muted.copyWith(color: color)),
          ],
        ),
        if (url != null) ...[
          const SizedBox(height: Space.l),
          Align(
            alignment: Alignment.centerLeft,
            child: DeskButton(
              icon: Icons.open_in_new,
              label: l10n.openInEcourse,
              primary: true,
              onPressed: () => openCampusPage(context, url, module.name),
            ),
          ),
        ],
        const SizedBox(height: Space.xl),
        progress,
        LayoutBuilder(
          builder: (context, box) {
            Widget column(List<Widget> children) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            );
            if (right.isEmpty) return column(left);
            if (box.maxWidth < 640) return column([...left, ...right]);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: column(left)),
                const SizedBox(width: 28),
                Expanded(child: column(right)),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Submission comments with the teacher and TAs, oldest first; one's own
/// can be deleted with a long press.
class _Comments extends StatefulWidget {
  const _Comments({required this.cmid, required this.submission});

  final int cmid, submission;

  @override
  State<_Comments> createState() => _CommentsState();
}

class _CommentsState extends State<_Comments> {
  late Future<({List<SubmissionComment> comments, bool canPost})> _load =
      _fetch();

  Future<({List<SubmissionComment> comments, bool canPost})> _fetch() => context
      .read<EcourseRepository>()
      .submissionComments(widget.cmid, widget.submission);

  void _reload() => setState(() => _load = _fetch());

  Future<void> _add() async {
    final l10n = context.l10n;
    final repo = context.read<EcourseRepository>();
    final sent = await compose(
      context,
      title: l10n.submissionComments,
      hint: l10n.commentHint,
      send: (_, text) =>
          repo.addSubmissionComment(widget.cmid, widget.submission, text),
    );
    if (sent && mounted) _reload();
  }

  Future<void> _delete(SubmissionComment c) async {
    final l10n = context.l10n;
    final ok = await showGlassDialog<bool>(
      context: context,
      builder: (context) => GlassDialog(
        title: l10n.deleteComment,
        content: Text(c.text, maxLines: 3, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<EcourseRepository>().deleteSubmissionComment(c.id);
      if (mounted) _reload();
    } catch (e) {
      if (mounted) showSendError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mint = context.tones.mint;
    return FutureBuilder(
      future: _load,
      builder: (context, snap) {
        final data = snap.data;
        if (snap.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(context.l10n.submissionComments),
              Row(
                children: [
                  Text(context.l10n.loadFailed),
                  TextButton(
                    onPressed: _reload,
                    child: Text(context.l10n.retry),
                  ),
                ],
              ),
            ],
          );
        }
        if (data == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionLabel(
              context.l10n.submissionComments,
              detail: '${data.comments.length}',
            ),
            for (final c in data.comments)
              InkWell(
                onLongPress: c.mine ? () => _delete(c) : null,
                borderRadius: BorderRadius.circular(Corners.small),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.xs,
                    vertical: Space.m,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: c.mine
                            ? mint.fill
                            : scheme.surfaceContainerHigh,
                        foregroundColor: c.mine
                            ? mint.ink
                            : scheme.onSurfaceVariant,
                        child: Text(
                          c.author.characters.firstOrNull ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: c.author,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '  ${dateTimeLabel(context, c.time)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            SelectableText(
                              c.text,
                              style: const TextStyle(height: 1.55),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (data.canPost)
              Padding(
                padding: const EdgeInsets.only(top: Space.s),
                child: ComposeBar(
                  hint: context.l10n.commentHint,
                  onTap: _add,
                  inline: true,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuizBody extends StatelessWidget {
  const _QuizBody({
    required this.quiz,
    required this.courseId,
    required this.module,
    this.onOpen,
  });

  final Quiz quiz;
  final int courseId;
  final Module module;

  /// Opens the quiz on eCourse2; its button shows once the quiz has loaded.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final q = quiz;
    final l10n = context.l10n;
    final now = clk.clock.now();
    final open = onOpen;
    final progress = _Progress(
      steps: [
        (
          l10n.stepOpens,
          q.opens == null ? '—' : monthDay(q.opens!),
          q.opens?.isBefore(now) ?? true,
        ),
        (
          l10n.stepAttempted,
          q.finished == null ? l10n.notAttempted : monthDay(q.finished!),
          q.finished != null,
        ),
        (
          l10n.stepCloses,
          q.closes == null ? '—' : monthDay(q.closes!),
          q.closes?.isBefore(now) ?? false,
        ),
        (l10n.stepGrade, q.grade ?? '—', q.grade != null),
      ],
    );
    final settings = <Widget>[
      SectionLabel(l10n.quizSettings),
      _Details(
        rows: [
          if (q.opens != null)
            (l10n.quizStart, dateTimeLabel(context, q.opens!)),
          if (q.closes != null)
            (l10n.quizEnd, dateTimeLabel(context, q.closes!)),
          (
            l10n.attemptsAllowed,
            q.attempts == 0 ? l10n.unlimited : l10n.attemptCount(q.attempts),
          ),
          (
            l10n.passGrade,
            q.pass == null ? l10n.fullMarks(q.max) : '${q.pass} / ${q.max}',
          ),
        ],
      ),
    ];
    final intro = <Widget>[
      if (q.intro.isNotEmpty) ...[
        SectionLabel(l10n.description),
        _Text(q.intro),
      ],
    ];
    if (desktopUi(context)) {
      final closes = q.closes;
      return _DeskModule(
        courseId: courseId,
        module: module,
        meta: [
          if (closes != null)
            (
              [
                '${dateTimeLabel(context, closes)} ${l10n.stepCloses}',
                if (closes.isAfter(now)) timeLeft(l10n, closes),
              ].join('・'),
              null,
            ),
          (
            q.finished == null
                ? l10n.notAttempted
                : '${l10n.stepAttempted} ${monthDay(q.finished!)}',
            q.finished == null ? context.tones.peach.strong : null,
          ),
        ],
        progress: progress,
        left: settings,
        right: intro,
      );
    }
    final list = ListView(
      padding: scrollPadding(context),
      children: [progress, ...settings, ...intro],
    );
    if (open == null) return list;
    // As the forum's 新討論: over the list, clear of the nav bar.
    return Stack(
      children: [
        list,
        Positioned(
          right: pageMargin,
          bottom: MediaQuery.paddingOf(context).bottom + 16,
          child: FloatingAction(
            icon: Icons.open_in_new,
            label: l10n.openInEcourse,
            onPressed: open,
          ),
        ),
      ],
    );
  }
}

class _FilesBody extends StatelessWidget {
  const _FilesBody({required this.files});

  final List<ModuleFile> files;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return EmptyState(context.l10n.noFiles);
    final latest = files
        .map((f) => f.modified)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final total = files.fold(0, (sum, f) => sum + f.size);
    return ListView(
      padding: scrollPadding(context),
      children: [
        Row(
          children: [
            _Fact(value: '${files.length}', label: context.l10n.filesLabel),
            const SizedBox(width: 8),
            _Fact(value: fileSize(total), label: context.l10n.total),
            const SizedBox(width: 8),
            _Fact(value: monthDay(latest), label: context.l10n.lastUpdated),
          ],
        ),
        const SizedBox(height: 12),
        FileList(
          files: files,
          detail: (f) =>
              context.l10n.fileUpdated(fileSize(f.size), monthDay(f.modified)),
        ),
      ],
    );
  }
}

/// Four milestones in a row. Done steps are mint checks; a done grade is the
/// peach star the page builds up to. The first step after the last done one
/// is current; an undone step before a done one was missed (e.g. a quiz that
/// closed without an attempt).
class _Progress extends StatelessWidget {
  const _Progress({required this.steps});

  final List<(String label, String value, bool done)> steps;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final lastDone = steps.lastIndexWhere((s) => s.$3);
    if (desktopUi(context)) {
      // design/round-25: a bar over each step, mint once done and lilac
      // for the one at hand.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, (label, value, done)) in steps.indexed) ...[
            if (i > 0) const SizedBox(width: Space.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: done
                          ? tones.mint.strong
                          : i == lastDone + 1
                          ? scheme.primary
                          : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: Space.s),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: !done && i == lastDone + 1
                          ? tones.peach.strong
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }
    return Card(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.s, Space.l, Space.s, Space.l),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, (label, value, done)) in steps.indexed)
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: i == 0
                              ? const SizedBox()
                              : Divider(
                                  thickness: 2,
                                  color: steps[i - 1].$3 && done
                                      ? tones.mint.strong
                                      : scheme.outlineVariant,
                                ),
                        ),
                        _Dot(
                          state: done
                              ? (i == steps.length - 1
                                    ? _DotState.star
                                    : _DotState.done)
                              : i < lastDone
                              ? _DotState.missed
                              : i == lastDone + 1
                              ? _DotState.current
                              : _DotState.later,
                        ),
                        Expanded(
                          child: i == steps.length - 1
                              ? const SizedBox()
                              : Divider(
                                  thickness: 2,
                                  color: done && steps[i + 1].$3
                                      ? tones.mint.strong
                                      : scheme.outlineVariant,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _DotState { done, star, current, missed, later }

class _Dot extends StatelessWidget {
  const _Dot({required this.state});

  final _DotState state;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final (fill, ink, icon) = switch (state) {
      _DotState.done => (tones.mint.strong, tones.mint.fill, Icons.check),
      _DotState.star => (tones.peach.strong, tones.peach.fill, Icons.star),
      _DotState.current => (tones.peach.fill, tones.peach.ink, null),
      _DotState.missed => (
        scheme.surfaceContainerHigh,
        scheme.onSurfaceVariant,
        Icons.close,
      ),
      _DotState.later => (
        scheme.surfaceContainerHigh,
        scheme.onSurfaceVariant,
        null,
      ),
    };
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: icon == null ? null : Icon(icon, size: 18, color: ink),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (desktopUi(context)) {
      return Column(
        children: [
          for (final (label, value) in rows)
            DeskLine(title: label, value: value),
        ],
      );
    }
    return Card(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.l,
          vertical: Space.s,
        ),
        child: Column(
          children: [
            for (final (i, (label, value)) in rows.indexed) ...[
              if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.m),
                child: Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.value, required this.label});

  final String value, label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: ToneBlock(
        tone: Tone(
          scheme.surfaceContainerHigh,
          scheme.onSurface,
          scheme.onSurfaceVariant,
        ),
        radius: Corners.row,
        padding: const EdgeInsets.all(Space.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Text extends StatelessWidget {
  const _Text(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    if (desktopUi(context)) {
      return Padding(
        padding: const EdgeInsets.only(top: Space.m),
        child: SelectableText(
          text,
          style: const TextStyle(
            fontSize: 14,
            height: 1.75,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: cardPadding,
        child: SelectableText(
          text,
          style: const TextStyle(height: 1.6, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class FileList extends StatelessWidget {
  const FileList({super.key, required this.files, required this.detail});

  final List<ModuleFile> files;
  final String Function(ModuleFile) detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (desktopUi(context)) {
      return Column(
        children: [for (final f in files) _FileRow(file: f, detail: detail(f))],
      );
    }
    return Card(
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, f) in files.indexed) ...[
            if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
            _FileRow(file: f, detail: detail(f)),
          ],
        ],
      ),
    );
  }
}

/// Downloads its file and shows it in the system's viewer.
class _FileRow extends StatefulWidget {
  const _FileRow({required this.file, required this.detail});

  final ModuleFile file;
  final String detail;

  @override
  State<_FileRow> createState() => _FileRowState();
}

class _FileRowState extends State<_FileRow> {
  var _saving = false;

  Future<void> _open() async {
    setState(() => _saving = true);
    try {
      final file = await context.read<EcourseRepository>().download(
        widget.file,
      );
      if (mounted) await showFile(context, file, widget.file.name);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.loadFailed)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trailing = _saving
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(
            Icons.download_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          );
    if (desktopUi(context)) {
      return DeskRow(
        leading: Icon(
          Icons.insert_drive_file_outlined,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
        title: widget.file.name,
        subtitle: widget.detail,
        trailing: trailing,
        onTap: _saving ? null : _open,
      );
    }
    return ListTile(
      leading: _FileIcon(
        name: widget.file.name,
        tones: context.tones,
        scheme: scheme,
      ),
      title: Text(
        widget.file.name,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(widget.detail),
      trailing: _saving
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Icon(Icons.download_rounded, color: scheme.onSurfaceVariant),
      onTap: _saving ? null : _open,
    );
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon({
    required this.name,
    required this.tones,
    required this.scheme,
  });

  final String name;
  final Tones tones;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final ext = name.split('.').last.toLowerCase();
    final (tone, icon) = switch (ext) {
      'pdf' => (tones.lilac, Icons.picture_as_pdf_outlined),
      'zip' ||
      'gz' ||
      'tgz' ||
      'rar' ||
      '7z' => (tones.sun, Icons.folder_zip_outlined),
      'ppt' ||
      'pptx' ||
      'doc' ||
      'docx' => (tones.identity[2], Icons.slideshow_outlined),
      _ => (
        Tone(
          scheme.surfaceContainerHigh,
          scheme.onSurface,
          scheme.onSurfaceVariant,
        ),
        Icons.insert_drive_file_outlined,
      ),
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: tone.fill,
        borderRadius: BorderRadius.circular(Corners.small),
      ),
      child: Icon(icon, size: 20, color: tone.ink),
    );
  }
}
