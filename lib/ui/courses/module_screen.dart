import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../../l10n/l10n.dart';

/// Module types with a page of their own; others open on eCourse2.
const moduleTypesWithPage = {'assign', 'quiz', 'folder', 'resource'};

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
        body: switch (module?.type) {
          null => EmptyState(context.l10n.itemNotFound),
          'assign' => Loader<Assignment>.watch(
            watch: () => repo.watch(
              (repo) => repo.assignment(courseId, module!.instance),
            ),
            builder: (context, a) => _AssignmentBody(assignment: a),
          ),
          'quiz' => Loader<Quiz>.watch(
            watch: () =>
                repo.watch((repo) => repo.quiz(courseId, module!.instance)),
            builder: (context, q) => _QuizBody(quiz: q),
          ),
          _ => _FilesBody(files: module!.files),
        },
      ),
    );
  }
}

String _day(DateTime d) => '${d.month}/${d.day}';
String _stamp(DateTime d) => '${_day(d)} ${clock(d.hour * 60 + d.minute)}';

/// `10/13 週二 00:00`, for settings where the hour matters.
String _full(BuildContext context, DateTime d) =>
    '${_day(d)} ${weekdayName(context, d.weekday)} ${clock(d.hour * 60 + d.minute)}';

String _size(int bytes) => switch (bytes) {
  < 1024 => '$bytes B',
  < 1024 * 1024 => '${(bytes / 1024).round()} KB',
  _ => '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB',
};

class _AssignmentBody extends StatelessWidget {
  const _AssignmentBody({required this.assignment});

  final Assignment assignment;

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
              a.opens == null ? '—' : _day(a.opens!),
              a.opens?.isBefore(now) ?? true,
            ),
            (
              l10n.stepSubmitted,
              a.submittedAt == null ? l10n.notSubmitted : _day(a.submittedAt!),
              a.submittedAt != null,
            ),
            (
              l10n.stepDue,
              a.due == null ? '—' : _day(a.due!),
              a.due?.isBefore(now) ?? false,
            ),
            (l10n.stepGrade, a.grade ?? '—', a.grade != null),
          ],
        ),
        if (a.submission.isNotEmpty) ...[
          SectionLabel(l10n.mySubmission),
          _FileList(files: a.submission, detail: (f) => _stamp(f.modified)),
        ],
        if (a.intro.isNotEmpty) ...[
          SectionLabel(l10n.description),
          _Text(a.intro),
        ],
        if (a.attachments.isNotEmpty) ...[
          SectionLabel(l10n.attachments),
          _FileList(files: a.attachments, detail: (f) => _size(f.size)),
        ],
      ],
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
              q.opens == null ? '—' : _day(q.opens!),
              q.opens?.isBefore(now) ?? true,
            ),
            (
              l10n.stepAttempted,
              q.finished == null ? l10n.notAttempted : _day(q.finished!),
              q.finished != null,
            ),
            (
              l10n.stepCloses,
              q.closes == null ? '—' : _day(q.closes!),
              q.closes?.isBefore(now) ?? false,
            ),
            (l10n.stepGrade, q.grade ?? '—', q.grade != null),
          ],
        ),
        SectionLabel(l10n.quizSettings),
        _Details(
          rows: [
            if (q.opens != null) (l10n.quizStart, _full(context, q.opens!)),
            if (q.closes != null) (l10n.quizEnd, _full(context, q.closes!)),
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
            _Fact(value: _size(total), label: context.l10n.total),
            const SizedBox(width: 8),
            _Fact(value: _day(latest), label: context.l10n.lastUpdated),
          ],
        ),
        const SizedBox(height: 12),
        _FileList(
          files: files,
          detail: (f) =>
              context.l10n.fileUpdated(_size(f.size), _day(f.modified)),
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
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          children: [
            for (final (i, (label, value)) in rows.indexed) ...[
              if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
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
        padding: const EdgeInsets.all(12),
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
        padding: const EdgeInsets.all(14),
        child: SelectableText(
          text,
          style: const TextStyle(height: 1.6, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _FileList extends StatelessWidget {
  const _FileList({required this.files, required this.detail});

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
