import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../domain/models/course.dart';
import '../../domain/models/timetable.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../../l10n/l10n.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  int _day = DateTime.now().weekday;

  /// Class shown beside the week grid in a wide window.
  DaySlot? _picked;

  /// Chosen semester; null follows the newest one.
  String? _semester;

  /// One page per weekday shown; rebuilt when the semester changes.
  PageController? _pages;

  /// Shared by every card, so swiping between days asks eCourse2 once.
  late final Stream<_Shared> _shared = context.read<EcourseRepository>().watch((
    repo,
  ) async {
    final (due, grades) = await (
      repo.dueSoon(days: 60),
      repo.gradeOverview(),
    ).wait;
    return (due: due, grades: grades);
  });

  /// The progress bar and countdowns move with the clock.
  late final _tick = Timer.periodic(
    const Duration(minutes: 1),
    (_) => setState(() {}),
  );

  @override
  void initState() {
    super.initState();
    _tick;
  }

  @override
  void dispose() {
    _tick.cancel();
    _pages?.dispose();
    super.dispose();
  }

  void _pickSemester(String semester) {
    _pages?.dispose();
    setState(() {
      _semester = semester;
      _pages = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Scaffold(
      body: Loader<List<Course>>.watch(
        capsuleInBody: true,
        watch: () => repo.watch((repo) => repo.courses()),
        builder: (context, all) {
          // Courses come newest first; a set keeps that order.
          final semesters = {for (final c in all) c.semester}.toList();
          final semester =
              _semester ?? (semesters.isEmpty ? '' : semesters.first);
          final courses = all.where((c) => c.semester == semester).toList();
          final days = {
            for (final c in courses)
              for (final s in c.sessions) s.weekday,
          };
          final weekdays = [
            for (var d = 1; d <= 7; d++)
              if (d <= 5 || days.contains(d)) d,
          ];
          // A weekend day without classes falls back to the last day shown.
          final page = weekdays.contains(_day)
              ? weekdays.indexOf(_day)
              : weekdays.length - 1;
          final pages = _pages ??= PageController(initialPage: page);
          final wide = MediaQuery.sizeOf(context).width >= wideLayout;
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: topBar(
              context.l10n.navTimetable,
              actions: [
                IconButton(
                  tooltip: context.l10n.searchCourses,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainer,
                  ),
                  onPressed: () => context.push('/courses'),
                  icon: const Icon(Icons.search),
                ),
                const SizedBox(width: 8),
                if (semesters.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: Space.l),
                    child: _SemesterMenu(
                      semesters: semesters,
                      selected: semester,
                      counts: {
                        for (final s in semesters)
                          s: all.where((c) => c.semester == s).length,
                      },
                      onSelected: _pickSemester,
                    ),
                  ),
              ],
              // Days stay pinned in the glass bar while classes scroll.
              bottom: wide
                  ? null
                  : PreferredSize(
                      preferredSize: const Size.fromHeight(64),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Space.m,
                          0,
                          Space.m,
                          Space.m,
                        ),
                        child: Row(
                          children: [
                            for (final (i, d) in weekdays.indexed)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  child: _DayPill(
                                    label: weekdayShort(context, d),
                                    selected: i == page,
                                    busy: days.contains(d),
                                    onTap: () => pages.animateToPage(
                                      i,
                                      duration: const Duration(
                                        milliseconds: 420,
                                      ),
                                      curve: Curves.easeOutQuart,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
            body: CapsuleArea(
              child: StreamBuilder<_Shared>(
                stream: _shared,
                builder: (context, shared) => wide
                    ? _week(context, courses, weekdays, shared.data)
                    : PageView(
                        controller: pages,
                        // A day pill lighting up ticks, however it was reached.
                        onPageChanged: (i) {
                          HapticFeedback.selectionClick();
                          setState(() => _day = weekdays[i]);
                        },
                        children: [
                          for (final d in weekdays)
                            _DayView(
                              courses: courses,
                              day: d,
                              now: DateTime.now(),
                              shared: shared.data,
                            ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Desktop direction A: the whole week, and the picked class beside it;
  /// before a pick, today's class in focus.
  Widget _week(
    BuildContext context,
    List<Course> courses,
    List<int> weekdays,
    _Shared? shared,
  ) {
    final now = DateTime.now();
    final minute = now.hour * 60 + now.minute;
    final today = [
      for (final c in courses)
        for (final s in c.sessions)
          if (s.weekday == now.weekday) (course: c, session: s),
    ]..sort((a, b) => a.session.start.compareTo(b.session.start));
    int order(DaySlot s) => s.session.weekday * 24 * 60 + s.session.start;
    // A day without classes left: the week's first class.
    final week = [
      for (final c in courses)
        for (final s in c.sessions) (course: c, session: s),
    ]..sort((a, b) => order(a).compareTo(order(b)));
    final picked =
        _picked ??
        dayFocus(today, today: true, minute: minute).focus ??
        week.firstOrNull;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            padding: scrollPadding(context, maxWidth: double.infinity),
            children: [
              _WeekGrid(
                courses: courses,
                weekdays: weekdays,
                today: now.weekday,
                picked: picked,
                onPick: (s) => setState(() => _picked = s),
              ),
            ],
          ),
        ),
        SizedBox(
          width: paneWidth,
          child: PaneSize(
            child: ListView(
              padding: scrollPadding(context).copyWith(left: 0),
              children: [
                if (picked != null)
                  _FocusCard(
                    slot: picked,
                    minute: picked.session.weekday == now.weekday
                        ? minute
                        : null,
                    shared: shared,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Monday to Friday (and a weekend day with classes) side by side, each
/// class placed by its clock times.
class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    required this.courses,
    required this.weekdays,
    required this.today,
    required this.picked,
    required this.onPick,
  });

  final List<Course> courses;
  final List<int> weekdays;
  final int today;
  final DaySlot? picked;
  final ValueChanged<DaySlot> onPick;

  static const _perMinute = 0.9;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sessions = [for (final c in courses) ...c.sessions];
    // Whole hours around the week's classes; 8:00–17:00 when there are none.
    final first = sessions.isEmpty
        ? 8 * 60
        : sessions.map((s) => s.start).reduce((a, b) => a < b ? a : b) ~/
              60 *
              60;
    final last = sessions.isEmpty
        ? 17 * 60
        : (sessions.map((s) => s.end).reduce((a, b) => a > b ? a : b) + 59) ~/
              60 *
              60;
    final height = (last - first) * _perMinute;
    final mute = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: scheme.onSurfaceVariant,
    );
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 44),
            for (final d in weekdays)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Space.s),
                  child: Text(
                    weekdayName(context, d),
                    textAlign: TextAlign.center,
                    style: d == today
                        ? mute.copyWith(color: context.tones.lilac.strong)
                        : mute,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 44,
                child: Stack(
                  children: [
                    for (var m = first; m < last; m += 60)
                      Positioned(
                        top: (m - first) * _perMinute,
                        right: 6,
                        child: Text(
                          clock(m),
                          style: mute.copyWith(fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
              for (final d in weekdays)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: d == today
                          ? scheme.surfaceContainer
                          : Color.lerp(
                              scheme.surface,
                              scheme.surfaceContainer,
                              0.5,
                            ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        for (final c in courses)
                          for (final s in c.sessions)
                            if (s.weekday == d)
                              Positioned(
                                top: (s.start - first) * _perMinute,
                                height: (s.end - s.start) * _perMinute - 2,
                                left: 0,
                                right: 0,
                                child: _WeekBlock(
                                  slot: (course: c, session: s),
                                  picked:
                                      picked?.course.id == c.id &&
                                      picked?.session.weekday == d &&
                                      picked?.session.start == s.start,
                                  onTap: () => onPick((course: c, session: s)),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekBlock extends StatelessWidget {
  const _WeekBlock({
    required this.slot,
    required this.picked,
    required this.onTap,
  });

  final DaySlot slot;
  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.forCourse(slot.course.id);
    return PressFeedback(
      scale: 0.97,
      haptic: HapticFeedback.selectionClick,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: tone.strong,
            borderRadius: BorderRadius.circular(10),
            border: picked
                ? Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 3,
                  )
                : null,
          ),
          child: Text.rich(
            TextSpan(
              text: context.courseName(slot.course),
              children: [
                if (slot.course.room case final room?)
                  TextSpan(
                    text: '\n$room',
                    style: TextStyle(color: tone.fill.withValues(alpha: 0.7)),
                  ),
              ],
            ),
            overflow: TextOverflow.fade,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1.3,
              color: tone.fill,
            ),
          ),
        ),
      ),
    );
  }
}

typedef DaySlot = ({Course course, ClassSession session});

/// Which class of the day leads, and which gets the next-class card. Today:
/// the class on now, else the next one, and the class after it only while
/// one is in progress (before the first class the focus card already says
/// 下一堂). Other days: the first class, alone.
({DaySlot? focus, DaySlot? after}) dayFocus(
  List<DaySlot> slots, {
  required bool today,
  required int minute,
}) {
  final focus = today
      ? slots.where((s) => s.session.end > minute).firstOrNull
      : null;
  // Another day, or today once its classes are over: the first class.
  if (focus == null) return (focus: slots.firstOrNull, after: null);
  final inClass = focus.session.start <= minute;
  return (
    focus: focus,
    after: inClass
        ? slots.skipWhile((s) => s != focus).skip(1).firstOrNull
        : null,
  );
}

/// Deadlines and grades for every course, loaded once for the screen.
typedef _Shared = ({List<DueItem> due, Map<int, String> grades});

/// Design round-11 timetable 2C: one class in focus with its period
/// progress, deadline, notice and grade; on today the class after it gets
/// its own card; the rest are one line each, those already over dimmed.
class _DayView extends StatelessWidget {
  const _DayView({
    required this.courses,
    required this.day,
    required this.now,
    required this.shared,
  });

  final List<Course> courses;
  final int day;
  final DateTime now;
  final _Shared? shared;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final slots = <DaySlot>[
      for (final c in courses)
        for (final s in c.sessions)
          if (s.weekday == day) (course: c, session: s),
    ]..sort((a, b) => a.session.start.compareTo(b.session.start));
    final minute = now.hour * 60 + now.minute;
    // Once today's classes are over it reads like any other day.
    final today =
        day == now.weekday && slots.any((s) => s.session.end > minute);
    final (:focus, :after) = dayFocus(slots, today: today, minute: minute);
    return ListView(
      padding: scrollPadding(context),
      children: [
        if (slots.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Center(
              child: Text(
                l10n.noClassesThisDay,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        for (final s in slots)
          if (s == focus)
            Padding(
              padding: const EdgeInsets.only(bottom: rowGap),
              child: _FocusCard(
                slot: s,
                minute: today ? minute : null,
                shared: shared,
              ),
            )
          else if (s == after)
            Padding(
              padding: const EdgeInsets.only(bottom: rowGap),
              child: _NextCard(slot: s, minute: minute, shared: shared),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s),
              child: Opacity(
                opacity: today && s.session.end <= minute ? 0.45 : 1,
                child: _ClassLine(slot: s),
              ),
            ),
        if (slots.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Space.xs),
            child: Text(
              l10n.classesEndAt(
                clock(
                  slots
                      .map((s) => s.session.end)
                      .reduce((a, b) => a > b ? a : b),
                ),
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (courses.any((c) => c.sessions.isEmpty)) ...[
          SectionLabel(l10n.unscheduled),
          for (final c in courses.where((c) => c.sessions.isEmpty))
            InkWell(
              onTap: () => context.push('/courses/${c.id}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.s),
                child: Text(
                  context.courseName(c),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// `CD` for lettered periods; `8–9` for numbered ones, which would
/// otherwise read as one number.
String periodLabel(List<String> periods) =>
    periods.length > 1 && int.tryParse(periods.first) != null
    ? '${periods.first}–${periods.last}'
    : periods.join();

/// `2 小時後` or `25 分鐘後`.
String _until(AppLocalizations l10n, int minutes) => minutes >= 60
    ? '${minutes ~/ 60} ${l10n.unitHoursLater}'
    : '$minutes ${l10n.unitMinutesLater}';

/// What the cards show beside the timetable: the course's nearest deadline,
/// newest notice and current grade, from eCourse2's saved answers first.
typedef _Facts = ({DueItem? due, String? post, String? grade});

class _FactsLoader extends StatefulWidget {
  const _FactsLoader({
    required this.courseId,
    required this.shared,
    required this.builder,
  });

  final int courseId;
  final _Shared? shared;
  final Widget Function(BuildContext context, _Facts? facts) builder;

  @override
  State<_FactsLoader> createState() => _FactsLoaderState();
}

class _FactsLoaderState extends State<_FactsLoader> {
  // Made once per course: the screen rebuilds every minute for the clock.
  late Stream<String?> _post = _load();

  /// The course's newest notice; `[公告] …` loses its tag, since the tile
  /// already says it is a notice.
  Stream<String?> _load() {
    final courseId = widget.courseId;
    return context.read<EcourseRepository>().watch(
      (repo) async =>
          (await repo.announcements(courseId)).firstOrNull?.subject
              .replaceFirst(RegExp(r'^\s*(\[[^\]]*\]|【[^】]*】)\s*'), ''),
    );
  }

  @override
  void didUpdateWidget(_FactsLoader old) {
    super.didUpdateWidget(old);
    if (old.courseId != widget.courseId) _post = _load();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<String?>(
    stream: _post,
    // A failure leaves the card without its extras, not an error.
    builder: (context, snap) {
      final shared = widget.shared;
      if (shared == null && !snap.hasData) return widget.builder(context, null);
      return widget.builder(context, (
        due: shared?.due
            .where((d) => d.courseId == widget.courseId)
            .firstOrNull,
        post: snap.data,
        grade: shared?.grades[widget.courseId],
      ));
    },
  );
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.slot,
    required this.minute,
    required this.shared,
  });

  final DaySlot slot;
  final _Shared? shared;

  /// Now, in minutes after midnight, when the day shown is today.
  final int? minute;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = slot.course;
    final s = slot.session;
    final tone = context.tones.forCourse(c.id);
    final now = minute;
    final label = now == null
        ? null
        : now >= s.start
        ? l10n.inClass
        : '${l10n.nextClass}・${_until(l10n, s.start - now)}';
    final small = TextStyle(
      color: tone.ink.withValues(alpha: 0.8),
      fontSize: 11,
      fontWeight: FontWeight.w900,
    );
    Widget fact(String title, String value) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.m,
        vertical: Space.m,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(Corners.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: small),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
    return ToneBlock(
      tone: tone,
      padding: const EdgeInsets.all(Space.xl),
      onTap: () => context.push('/courses/${c.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (label != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: Space.m),
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.m,
                          vertical: Space.xs,
                        ),
                        decoration: ShapeDecoration(
                          color: tone.strong,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: tone.fill,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    Text(
                      context.courseName(c),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final (icon, line) in [
                      if (c.room case final room?) (Icons.place_outlined, room),
                      for (final t in c.teachers.take(1))
                        (Icons.person_outline, t),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                icon,
                                size: 15,
                                color: tone.ink.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                line,
                                style: TextStyle(
                                  color: tone.ink.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CookieBadge(
                value: periodLabel(s.periods),
                color: tone.strong,
                ink: tone.fill,
                size: 56,
                shape: courseShape(c.id),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PeriodBar(session: s, minute: now, tone: tone),
          const SizedBox(height: 12),
          _FactsLoader(
            courseId: c.id,
            shared: shared,
            builder: (context, facts) {
              final due = facts?.due;
              final post = facts?.post;
              // eCourse2 answers `-` for a course without a grade yet.
              final grade = facts?.grade == '-' ? null : facts?.grade;
              final pair = [
                if (post != null) fact(l10n.latestPost, post),
                if (grade != null) fact(l10n.currentGrade, grade),
              ];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (due != null)
                    fact(
                      l10n.latestDue,
                      '${due.name}・${weekdayName(context, due.due.weekday)} '
                      '${clock(due.due.hour * 60 + due.due.minute)}',
                    ),
                  if (due != null && pair.isNotEmpty) const SizedBox(height: 8),
                  if (pair.isNotEmpty)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, tile) in pair.indexed) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(child: tile),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// One segment per period, filled as the clock passes through it, with
/// each period's letter and hours below.
class _PeriodBar extends StatelessWidget {
  const _PeriodBar({
    required this.session,
    required this.minute,
    required this.tone,
  });

  final ClassSession session;
  final int? minute;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final periods = [
      for (final code in session.periods)
        if (periodTime(code) case final t?)
          (code: code, start: t.start, end: t.end),
    ];
    final now = minute;
    final label = TextStyle(
      color: tone.ink.withValues(alpha: 0.8),
      fontSize: 11,
      fontWeight: FontWeight.w900,
    );
    // Another day: nothing to fill, so only each period's hours.
    if (now == null) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final p in periods)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.m,
                vertical: Space.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${p.code} ${clock(p.start)}–${clock(p.end)}',
                style: label,
              ),
            ),
        ],
      );
    }
    return Row(
      children: [
        for (final (i, p) in periods.indexed) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ((now - p.start) / (p.end - p.start)).clamp(0, 1),
                    minHeight: 8,
                    color: tone.ink,
                    backgroundColor: Colors.black.withValues(alpha: 0.22),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${p.code} ${clock(p.start)}–${clock(p.end)}',
                  style: label,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Today's class after the one in focus, with its own nearest deadline so
/// it can be prepared for.
class _NextCard extends StatelessWidget {
  const _NextCard({
    required this.slot,
    required this.minute,
    required this.shared,
  });

  final DaySlot slot;
  final _Shared? shared;
  final int minute;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = slot.course;
    final tone = context.tones.forCourse(c.id);
    return ToneBlock(
      tone: tone,
      padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.l),
      onTap: () => context.push('/courses/${c.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [l10n.nextClass, ?c.room].join('・'),
                      style: TextStyle(
                        color: tone.ink.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      context.courseName(c),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    clock(slot.session.start),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  Text(
                    _until(l10n, slot.session.start - minute),
                    style: TextStyle(
                      color: tone.ink.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _FactsLoader(
            courseId: c.id,
            shared: shared,
            builder: (context, facts) {
              final due = facts?.due;
              if (due == null) return const SizedBox();
              return Container(
                margin: const EdgeInsets.only(top: Space.m),
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.m,
                  vertical: Space.s,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(Corners.small),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_outlined, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        due.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${weekdayName(context, due.due.weekday)} '
                      '${clock(due.due.hour * 60 + due.due.minute)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Any other class of the day: time, name and room on one line.
class _ClassLine extends StatelessWidget {
  const _ClassLine({required this.slot});

  final DaySlot slot;

  @override
  Widget build(BuildContext context) {
    final c = slot.course;
    final s = slot.session;
    final tone = context.tones.forCourse(c.id);
    return ToneBlock(
      tone: tone,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.l,
        vertical: Space.m,
      ),
      onTap: () => context.push('/courses/${c.id}'),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(
              clock(s.start),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.courseName(c),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  [?c.room, clock(s.end)].join('・'),
                  style: TextStyle(
                    color: tone.ink.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          CookieBadge(
            value: periodLabel(s.periods),
            color: tone.strong,
            ink: tone.fill,
            size: 36,
            shape: courseShape(c.id),
          ),
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.label,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool selected, busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = context.tones.lilac;
    // Sinks with the nav bar's selection click, like the app bar chips.
    return PressFeedback(
      scale: 0.92,
      haptic: HapticFeedback.selectionClick,
      child: Material(
        color: selected ? tone.strong : scheme.surfaceContainerHigh,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.m),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: selected ? tone.fill : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: busy
                        ? (selected ? tone.fill : tone.strong)
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// App bar capsule showing the semester being viewed; opens a glass list of
/// every semester with its course count (design/round-11, variant M1).
class _SemesterMenu extends StatelessWidget {
  const _SemesterMenu({
    required this.semesters,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final List<String> semesters;
  final String selected;
  final Map<String, int> counts;
  final ValueChanged<String> onSelected;

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final picked = await showGlassMenu<String>(
      context,
      anchor: box.localToGlobal(Offset.zero) & box.size,
      selected: selected,
      items: [
        for (final s in semesters)
          (
            value: s,
            title: semesterName(context, s),
            detail: context.l10n.courseCount(counts[s] ?? 0),
            icon: null,
            tone: null,
          ),
      ],
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.lilac;
    return Semantics(
      button: true,
      label: context.l10n.switchSemester,
      child: Material(
        color: tone.fill,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => _open(context),
          child: Container(
            height: 40,
            padding: const EdgeInsets.only(left: Space.l, right: Space.s),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  semesterShort(selected),
                  style: TextStyle(
                    color: tone.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: tone.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
