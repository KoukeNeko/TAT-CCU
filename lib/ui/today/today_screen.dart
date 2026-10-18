import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../domain/models/course.dart';
import '../../domain/models/timetable.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

// Layout follows design/round-01/c-deck.html: headline, one hero block,
// a pill for the next class, two count tiles.

typedef _Slot = ({Course course, ClassSession session});

typedef _Today = ({
  List<_Slot> slots,
  List<DueItem> due,
  int notices,
  int mail,
});

const _counts = ['零', '一', '兩', '三', '四', '五', '六', '七', '八', '九', '十'];

/// `創新大樓 322` → `322`; the pill only has room for the room number.
String _roomNumber(String? room) =>
    RegExp(r'\d+\S*$').stringMatch(room ?? '') ?? (room ?? '');

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  Future<_Today> _load(EcourseRepository repo) async {
    final now = DateTime.now();
    final results = await Future.wait([
      repo.currentCourses(),
      repo.dueSoon(days: 7),
      repo.unreadNotices(),
      repo.unreadMail(),
    ]);
    final slots = [
      for (final c in results[0] as List<Course>)
        for (final s in c.sessions)
          if (s.weekday == now.weekday) (course: c, session: s),
    ]..sort((a, b) => a.session.start.compareTo(b.session.start));
    return (
      slots: slots,
      due: results[1] as List<DueItem>,
      notices: results[2] as int,
      mail: results[3] as int,
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    final now = DateTime.now();
    return Scaffold(
      // Edge to edge: the list itself pads past the status bar.
      body: Loader<_Today>(
        load: () => _load(repo),
        builder: (context, d) {
          final minute = now.hour * 60 + now.minute;
          final remaining = d.slots
              .where((s) => s.session.end > minute)
              .toList();
          final current = remaining
              .where((s) => s.session.start <= minute)
              .firstOrNull;
          final next = remaining
              .where((s) => s.session.start > minute)
              .firstOrNull;
          final theme = Theme.of(context);
          final tones = context.tones;
          final n = remaining.length;
          final headline = d.slots.isEmpty
              ? '今天沒有課'
              : n == 0
              ? '今天的課結束了'
              : '今天還有${n < _counts.length ? _counts[n] : '$n '}堂課';
          final firstDue = d.due.firstOrNull;
          return ListView(
            padding: scrollPadding(context, top: 20),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${weekdayNames[now.weekday - 1]} ${now.month}/${now.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            headline,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _BellButton(
                      unread: d.notices + d.mail,
                      onTap: () => context.go('/today/notifications'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (current != null)
                _Hero(
                  slot: current,
                  label: '上課中',
                  detail: '到 ${clock(current.session.end)}',
                  minutes: current.session.end - minute,
                  unit: '分鐘',
                )
              else if (next != null)
                _Hero(
                  slot: next,
                  label: '下一堂',
                  detail: '${clock(next.session.start)} 開始',
                  minutes: next.session.start - minute,
                  unit: '分鐘後',
                ),
              if (current != null && next != null) ...[
                const SizedBox(height: 12),
                _NextPill(slot: next),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Tile(
                      tone: tones.peach,
                      value: '${d.due.length}',
                      label: '本週到期',
                      detail: firstDue == null
                          ? null
                          : '${firstDue.name} ${weekdayNames[firstDue.due.weekday - 1]} '
                                '${clock(firstDue.due.hour * 60 + firstDue.due.minute)}',
                      onTap: () => context.go('/today/due'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Tile(
                      tone: tones.sun,
                      value: '${d.notices + d.mail}',
                      label: '未讀',
                      detail: '通知 ${d.notices}・信件 ${d.mail}',
                      onTap: () => context.go('/today/notifications'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.slot,
    required this.label,
    required this.detail,
    required this.minutes,
    required this.unit,
  });

  final _Slot slot;
  final String label, detail, unit;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.lilac;
    return Material(
      color: tone.fill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/courses/${slot.course.id}'),
        child: SizedBox(
          height: 226,
          child: Stack(
            children: [
              // The badge sits partly outside the card, as in the mockup.
              Positioned(
                right: -22,
                bottom: -22,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: ShapeDecoration(
                    color: tone.strong,
                    shape: const StarBorder(
                      points: 11,
                      innerRadiusRatio: 0.78,
                      pointRounding: 0.15,
                      valleyRounding: 0.1,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 22,
                bottom: 40,
                width: 72,
                child: Column(
                  children: [
                    FittedBox(
                      child: Text(
                        '$minutes',
                        style: TextStyle(
                          color: tone.fill,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                    Text(
                      unit,
                      style: TextStyle(
                        color: tone.fill,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 120, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      slot.course.fullName,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tone.ink,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${slot.course.room ?? ''}・$detail',
                      style: TextStyle(
                        color: tone.ink.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextPill extends StatelessWidget {
  const _NextPill({required this.slot});

  final _Slot slot;

  @override
  Widget build(BuildContext context) {
    const bold = TextStyle(fontSize: 14, fontWeight: FontWeight.w800);
    return ToneBlock(
      tone: context.tones.mint,
      radius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      onTap: () => context.go('/courses/${slot.course.id}'),
      child: Row(
        children: [
          const Text('下一堂', style: bold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              slot.course.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bold,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${clock(slot.session.start)}・${_roomNumber(slot.course.room)}',
            style: bold,
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.tone,
    required this.value,
    required this.label,
    this.detail,
    this.onTap,
  });

  final Tone tone;
  final String value, label;
  final String? detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ToneBlock(
      tone: tone,
      radius: 28,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: SizedBox(
        height: 88,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            if (detail != null)
              Text(
                detail!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tone.ink.withValues(alpha: 0.75),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Notifications live behind this bell instead of a nav tab; the badge is
/// the same unread count as the 未讀 tile.
class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread, required this.onTap});

  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sun = context.tones.sun;
    return Semantics(
      button: true,
      label: unread > 0 ? '通知，$unread 則未讀' : '通知',
      child: Material(
        color: scheme.surfaceContainer,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_none, color: scheme.onSurface),
                if (unread > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: ShapeDecoration(
                        color: sun.strong,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: TextStyle(
                          color: sun.fill,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
