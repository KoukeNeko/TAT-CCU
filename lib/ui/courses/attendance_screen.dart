import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../data/services/demo_data.dart';
import '../../l10n/l10n.dart';
import '../core/auto_refresh.dart';
import '../core/campus_session.dart';
import '../core/desk_list.dart';
import '../core/desktop_mode.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../../data/services/ecourse_web.dart';
import 'course_detail_screen.dart';

/// An attendance activity (design/round-11 course-modules-screens): the
/// attendance rate as the hero, then every session's status and points.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, required this.cmid, this.title});

  final int cmid;
  final String? title;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with AutoRefresh, CampusPageState {
  @override
  String get cacheKey => 'attendance-${widget.cmid}';

  Attendance? get _data => json == null ? null : attendanceOf(json!);

  /// The route's course, for the desktop UI's path and heading.
  late final _courseId = int.parse(
    GoRouterState.of(context).pathParameters['id']!,
  );
  late final _name = widget.title != null
      ? Future.value(widget.title)
      : moduleName(context.read<EcourseRepository>(), _courseId, widget.cmid);

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return CampusSession(
      key: session,
      title: widget.title ?? '',
      titleChild: desktopUi(context)
          ? FutureBuilder(
              future: _name,
              builder: (context, name) => CourseCrumbs(
                courseId: _courseId,
                trail: [context.l10n.allSections, name.data ?? ''],
              ),
            )
          : null,
      entry: ecourseEntry,
      host: ecourseHost,
      loadOnStart: false,
      script: () => readAttendance(widget.cmid),
      demo: DemoCampus.attendance,
      onMessage: received,
      child: error != null
          ? CampusError(message: error!, onRetry: retry)
          : data == null
          ? null
          : Builder(
              builder: (context) => PullRefresh(
                onRefresh: () async => session.currentState?.refresh(),
                child: _body(context, data),
              ),
            ),
    );
  }

  Widget _body(BuildContext context, Attendance data) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    if (data.sessions.isEmpty) return EmptyState(l10n.noAttendance);
    final counts = <String, int>{};
    for (final s in data.sessions) {
      if (s.status.isNotEmpty) counts[s.status] = (counts[s.status] ?? 0) + 1;
    }
    // Taken sessions newest first; the ones still to come in date order.
    final taken = [
      for (final s in data.sessions.reversed)
        if (s.status.isNotEmpty) s,
    ];
    final pending = [
      for (final s in data.sessions)
        if (s.status.isEmpty) s,
    ];
    if (desktopUi(context)) return _desk(context, data, counts, taken, pending);
    Widget list(List<AttendanceSession> sessions) => Card(
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, s) in sessions.indexed) ...[
            if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
            _SessionRow(session: s),
          ],
        ],
      ),
    );
    return ListView(
      padding: scrollPadding(context),
      children: [
        _Hero(data: data, counts: counts),
        if (taken.isNotEmpty) ...[
          SectionLabel(l10n.attendanceSessions, detail: '${taken.length}'),
          list(taken),
        ],
        if (pending.isNotEmpty) ...[
          SectionLabel(l10n.attendanceNotTaken, detail: '${pending.length}'),
          list(pending),
        ],
        if (savedAt case final time?) UpdatedAt(time),
      ],
    );
  }

  /// design/round-25: the module's head, the rate and counts in one box,
  /// then taken and coming sessions side by side, when it was read below.
  Widget _desk(
    BuildContext context,
    Attendance data,
    Map<String, int> counts,
    List<AttendanceSession> taken,
    List<AttendanceSession> pending,
  ) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    final line = BorderSide(color: scheme.outlineVariant);
    Widget session(AttendanceSession s) {
      final tone = _statusTone(context, s.status);
      final date = s.date;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: Space.s),
        decoration: BoxDecoration(border: Border(bottom: line)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date == null
                        ? s.description
                        : '${date.month}/${date.day} '
                              '${weekdayName(context, date.weekday)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: s.status.isEmpty
                          ? FontWeight.w700
                          : FontWeight.w800,
                      color: s.status.isEmpty ? scheme.onSurfaceVariant : null,
                    ),
                  ),
                  Text(s.time, style: muted),
                ],
              ),
            ),
            if (s.status.isNotEmpty) DeskTag(s.status, color: tone?.strong),
          ],
        ),
      );
    }

    Widget column(String title, List<AttendanceSession> sessions) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(title, detail: '${sessions.length}'),
        for (final s in sessions) session(s),
      ],
    );
    final rate = data.rate?.replaceAll('%', ' %');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: scrollPadding(context),
            children: [
              FutureBuilder(
                future: _name,
                builder: (context, name) => CoursePageHead(
                  courseId: _courseId,
                  kind: l10n.takeAttendance,
                  title: name.data ?? '',
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: Space.l,
                ),
                decoration: BoxDecoration(
                  border: Border.fromBorderSide(line),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rate ?? '-',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          [
                            l10n.attendanceRate,
                            if (data.taken case final n?)
                              '$n ${l10n.attendanceTakenUnit}',
                          ].join('・'),
                          style: muted,
                        ),
                      ],
                    ),
                    if (counts.isNotEmpty) ...[
                      const SizedBox(width: 28),
                      Container(
                        padding: const EdgeInsets.only(left: 28),
                        decoration: BoxDecoration(border: Border(left: line)),
                        child: Row(
                          spacing: 22,
                          children: [
                            for (final MapEntry(:key, :value) in counts.entries)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$value',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Row(
                                    spacing: 6,
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color:
                                              _statusTone(
                                                context,
                                                key,
                                              )?.strong ??
                                              scheme.onSurfaceVariant,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      Text(key, style: muted),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (data.points case final points?)
                      Text(
                        l10n.attendancePoints(points),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: column(l10n.attendanceSessions, taken)),
                  const SizedBox(width: 28),
                  Expanded(child: column(l10n.attendanceNotTaken, pending)),
                ],
              ),
            ],
          ),
        ),
        if (savedAt case final time?)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            decoration: BoxDecoration(border: Border(top: line)),
            child: Text(
              l10n.updatedAt(
                '${time.month}/${time.day} '
                '${clock(time.hour * 60 + time.minute)}',
              ),
              style: muted,
            ),
          ),
      ],
    );
  }
}

/// 出席 mint, 遲到 sun, leave lilac, 缺席 peach; anything else stays grey.
Tone? _statusTone(BuildContext context, String status) {
  final t = context.tones;
  return switch (status) {
    '出席' => t.mint,
    '遲到' || '早退' => t.sun,
    '缺席' || '曠課' => t.peach,
    _ when status.contains('假') => t.lilac,
    _ => null,
  };
}

class _Hero extends StatelessWidget {
  const _Hero({required this.data, required this.counts});

  final Attendance data;
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tone = context.tones.mint;
    final rate = data.rate?.replaceAll('%', '');
    return Material(
      color: tone.fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corners.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (data.taken case final taken?)
            Positioned(
              right: -8,
              bottom: -12,
              child: Container(
                width: 132,
                height: 132,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: tone.strong,
                  shape: const StarBorder(
                    points: 11,
                    innerRadiusRatio: 0.78,
                    pointRounding: 0.15,
                    valleyRounding: 0.1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      taken,
                      style: TextStyle(
                        color: tone.fill,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    Text(
                      l10n.attendanceTakenUnit,
                      style: TextStyle(
                        color: tone.fill,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.xl,
              Space.xl,
              140,
              Space.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.attendanceRate,
                  style: TextStyle(
                    color: tone.ink.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: rate ?? '-'),
                      if (rate != null)
                        const TextSpan(
                          text: '%',
                          style: TextStyle(fontSize: 18),
                        ),
                    ],
                  ),
                  style: TextStyle(
                    color: tone.ink,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                if (data.points case final points?)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.xs),
                    child: Text(
                      l10n.attendancePoints(points),
                      style: TextStyle(
                        color: tone.ink.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final MapEntry(:key, :value) in counts.entries)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.m,
                          vertical: Space.s,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$key $value',
                          style: TextStyle(
                            color: tone.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final AttendanceSession session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = session;
    final muted = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    final tone = _statusTone(context, s.status);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.l,
        vertical: Space.m,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: s.date == null
                ? const SizedBox()
                : Column(
                    children: [
                      Text(
                        '${s.date!.month}/${s.date!.day}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(weekdayName(context, s.date!.weekday), style: muted),
                    ],
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.description.isEmpty ? s.time : s.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  [
                    if (s.description.isNotEmpty) s.time,
                    if (s.remark.isNotEmpty) s.remark,
                  ].join('・'),
                  style: muted,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (s.status.isNotEmpty)
                tone == null
                    ? Text(s.status, style: muted)
                    : StatusPill(tone: tone, label: s.status),
              if (s.points.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Space.xs),
                  child: Text(s.points, style: muted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
