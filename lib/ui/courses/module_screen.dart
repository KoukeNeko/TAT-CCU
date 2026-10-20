import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../core/compose_screen.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../../l10n/l10n.dart';
import 'forum_screen.dart';

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
        appBar: subBar(context, module?.name ?? ''),
        body: CapsuleArea(
          child: switch (module?.type) {
            null => EmptyState(context.l10n.itemNotFound),
            'assign' => Loader<Assignment>.watch(
              watch: () => repo.watch(
                (repo) => repo.assignment(courseId, module!.instance),
              ),
              builder: (context, a) =>
                  _AssignmentBody(assignment: a, cmid: cmid),
            ),
            'forum' => ForumBody(courseId: courseId, forumId: module!.instance),
            'quiz' => Loader<Quiz>.watch(
              watch: () =>
                  repo.watch((repo) => repo.quiz(courseId, module!.instance)),
              builder: (context, q) => _QuizBody(quiz: q),
            ),
            _ => _FilesBody(files: module!.files),
          },
        ),
      ),
    );
  }
}

class _AssignmentBody extends StatelessWidget {
  const _AssignmentBody({required this.assignment, required this.cmid});

  final Assignment assignment;
  final int cmid;

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    final l10n = context.l10n;
    final now = DateTime.now();
    return ListView(
      padding: scrollPadding(context),
      children: [
        _Progress(
          steps: [
            (
              l10n.stepOpens,
              a.opens == null ? '—' : monthDay(a.opens!),
              a.opens?.isBefore(now) ?? true,
            ),
            (
              l10n.stepSubmitted,
              a.submittedAt == null
                  ? l10n.notSubmitted
                  : monthDay(a.submittedAt!),
              a.submittedAt != null,
            ),
            (
              l10n.stepDue,
              a.due == null ? '—' : monthDay(a.due!),
              a.due?.isBefore(now) ?? false,
            ),
            (l10n.stepGrade, a.grade ?? '—', a.grade != null),
          ],
        ),
        if (a.submission.isNotEmpty) ...[
          SectionLabel(l10n.mySubmission),
          FileList(
            files: a.submission,
            detail: (f) => monthDayTime(f.modified),
          ),
        ],
        if (a.intro.isNotEmpty) ...[
          SectionLabel(l10n.description),
          _Text(a.intro),
        ],
        if (a.attachments.isNotEmpty) ...[
          SectionLabel(l10n.attachments),
          FileList(files: a.attachments, detail: (f) => fileSize(f.size)),
        ],
        if (a.commentsOn case final submission?)
          _Comments(cmid: cmid, submission: submission),
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteComment),
        content: Text(c.text, maxLines: 3, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
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
  const _QuizBody({required this.quiz});

  final Quiz quiz;

  @override
  Widget build(BuildContext context) {
    final q = quiz;
    final l10n = context.l10n;
    final now = DateTime.now();
    return ListView(
      padding: scrollPadding(context),
      children: [
        _Progress(
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
        ),
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
        if (q.intro.isNotEmpty) ...[
          SectionLabel(l10n.description),
          _Text(q.intro),
        ],
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
    final repo = context.read<EcourseRepository>();
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, f) in files.indexed) ...[
            if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
            ListTile(
              leading: _FileIcon(name: f.name, tones: tones, scheme: scheme),
              title: Text(
                f.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(detail(f)),
              trailing: Icon(
                Icons.download_rounded,
                color: scheme.onSurfaceVariant,
              ),
              // In-app browser: the token in the URL stays out of Safari's
              // history.
              onTap: () => launchUrl(
                Uri.parse(repo.fileUrl(f.url)),
                mode: LaunchMode.inAppBrowserView,
              ),
            ),
          ],
        ],
      ),
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
