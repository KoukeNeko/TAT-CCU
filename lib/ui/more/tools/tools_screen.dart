import 'package:clock/clock.dart' as clk;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/bus_timetable.dart';
import '../../../data/services/school_calendar.dart';
import '../../../l10n/l10n.dart';
import '../../core/desk_list.dart';
import '../../core/desktop_mode.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'bus_screen.dart';

/// Design round-11 campus-tools-screens: one tile per tool, its name large
/// and one current fact small.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tones;
    final next = nextSchoolDate(clk.clock.now());
    final tiles = [
      (
        t.identity[2],
        Icons.directions_bus_outlined,
        l10n.toolBus,
        'bus',
        '7306・7309',
      ),
      (
        t.mint,
        Icons.flag_outlined,
        l10n.toolCountdown,
        'countdown',
        next == null
            ? null
            : '${next.title} ${daysTo(next.start)} ${l10n.daysUnit}',
      ),
    ];
    if (desktopUi(context)) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: subBar(context, l10n.tools),
        body: Builder(builder: (context) => _DeskTools(next: next)),
      );
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, l10n.tools),
      body: Builder(
        builder: (context) => GridView.count(
          padding: scrollPadding(context),
          crossAxisCount: 2,
          mainAxisSpacing: rowGap,
          crossAxisSpacing: rowGap,
          childAspectRatio: 1.3,
          children: [
            for (final (tone, icon, title, path, detail) in tiles)
              StatusTile(
                tone: tone,
                icon: icon,
                title: detail ?? title,
                status: detail == null ? null : title,
                onTap: () => context.push('/more/tools/$path'),
              ),
          ],
        ),
      ),
    );
  }
}

/// design/round-25 tools: each tool a box, its answer large.
class _DeskTools extends StatefulWidget {
  const _DeskTools({required this.next});

  final SchoolDate? next;

  @override
  State<_DeskTools> createState() => _DeskToolsState();
}

class _DeskToolsState extends State<_DeskTools> {
  final _timetable = loadBusTimetable();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final sub = TextStyle(
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    final next = widget.next;
    final term = termProgress(DateUtils.dateOnly(clk.clock.now()));
    return ListView(
      padding: scrollPadding(context),
      children: [
        Text(
          l10n.tools,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: Space.xl),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _DeskTool(
                  icon: Icons.directions_bus_outlined,
                  title: l10n.toolBus,
                  onTap: () => context.push('/more/tools/bus'),
                  child: FutureBuilder(
                    future: _timetable,
                    builder: (context, snapshot) {
                      final now = clk.clock.now();
                      final first = (nextDepartures(
                        snapshot.data?.trips ?? [],
                        now,
                      )..sort((a, b) => a.at.compareTo(b.at))).firstOrNull;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (first != null) ...[
                            _hero(
                              context,
                              busCountdown(context, first.at, now),
                            ),
                            Text(
                              '${first.trip.route}・'
                              '${clock(first.at.hour * 60 + first.at.minute)} '
                              '${first.trip.stop}${l10n.busDepartsShort}',
                              style: sub,
                            ),
                          ],
                          Text(
                            '7306・7309',
                            style: sub.copyWith(color: scheme.outline),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _DeskTool(
                  icon: Icons.flag_outlined,
                  title: l10n.toolCountdown,
                  onTap: () => context.push('/more/tools/countdown'),
                  child: next == null
                      ? Text(l10n.countdownEnded, style: sub)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _hero(
                              context,
                              daysTo(next.start) <= 0
                                  ? [l10n.countdownToday]
                                  : ['${daysTo(next.start)}', l10n.daysUnit],
                            ),
                            Text(
                              '${next.title}・${dayLabel(context, next.start)}',
                              style: sub,
                            ),
                            if (term != null) ...[
                              const SizedBox(height: Space.s),
                              DeskBar(
                                value: term.progress,
                                color: context.tones.lilac.strong,
                              ),
                            ],
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

  /// The answer large, its unit after it small.
  Widget _hero(BuildContext context, List<String> parts) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Text.rich(
      TextSpan(
        text: parts.first,
        children: [
          if (parts.length > 1)
            TextSpan(
              text: ' ${parts.skip(1).join(' ')}',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      style: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.1,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    ),
  );
}

/// A tool's box: its icon and name over [child], opening the tool.
class _DeskTool extends StatelessWidget {
  const _DeskTool({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.child,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DeskIcon(icon),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 16, color: scheme.outline),
                ],
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Whole days from today to [d].
int daysTo(DateTime d) =>
    DateUtils.dateOnly(d)
        .difference(DateUtils.dateOnly(clk.clock.now()))
        .inDays;

/// Each tool's main card: the answer large, what it rests on small.
class ToolHero extends StatelessWidget {
  const ToolHero({
    super.key,
    required this.tone,
    required this.label,
    required this.value,
    this.unit,
    this.detail,
    this.child,
  });

  final Tone tone;
  final String label, value;
  final String? unit, detail;

  /// Below the numbers, such as a gauge.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(
      color: tone.ink.withValues(alpha: 0.85),
      fontSize: 13,
      fontWeight: FontWeight.w800,
    );
    return ToneBlock(
      tone: tone,
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: muted),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: value),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 18,
                      color: tone.ink.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
            style: TextStyle(
              color: tone.ink,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(detail!, style: muted),
          ],
          ?child,
        ],
      ),
    );
  }
}
