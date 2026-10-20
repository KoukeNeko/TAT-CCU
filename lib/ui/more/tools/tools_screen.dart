import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/school_calendar.dart';
import '../../../l10n/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Design round-11 campus-tools-screens: one tile per tool, its name large
/// and one current fact small.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tones;
    final next = nextSchoolDate(DateTime.now());
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

/// Whole days from today to [d].
int daysTo(DateTime d) =>
    DateUtils.dateOnly(d).difference(DateUtils.dateOnly(DateTime.now())).inDays;

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
      padding: const EdgeInsets.all(18),
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
