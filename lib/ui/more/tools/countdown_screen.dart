import 'package:flutter/material.dart';

import '../../../data/services/school_calendar.dart';
import '../../../l10n/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'tools_screen.dart';

/// The school calendar's next dates, the nearest as the hero with how far
/// the term has come.
class CountdownScreen extends StatelessWidget {
  const CountdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final today = DateUtils.dateOnly(DateTime.now());
    final upcoming = [
      for (final d in schoolCalendar)
        if (!(d.end ?? d.start).isBefore(today)) d,
    ];
    final term = schoolTerms
        .where((s) => !today.isBefore(s.start) && !today.isAfter(s.end))
        .firstOrNull;
    String range(SchoolDate d) => [
      dayLabel(context, d.start),
      if (d.end case final end?) dayLabel(context, end),
    ].join(' – ');
    String until(SchoolDate d) {
      final n = daysTo(d.start);
      return n <= 0 ? l10n.countdownToday : '$n ${l10n.daysUnit}';
    }

    final first = upcoming.firstOrNull;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, l10n.toolCountdown),
      body: Builder(
        builder: (context) => first == null
            ? EmptyState(l10n.countdownEnded)
            : ListView(
                padding: scrollPadding(context),
                children: [
                  ToolHero(
                    tone: t.mint,
                    label: first.title,
                    value: daysTo(first.start) <= 0
                        ? l10n.countdownToday
                        : '${daysTo(first.start)}',
                    unit: daysTo(first.start) <= 0 ? null : l10n.daysUnit,
                    detail: range(first),
                    child: term == null
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: LinearProgressIndicator(
                                    value:
                                        today.difference(term.start).inDays /
                                        term.end.difference(term.start).inDays,
                                    minHeight: 10,
                                    color: t.mint.ink,
                                    backgroundColor: Colors.black.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.termWeek(
                                    today.difference(term.start).inDays ~/ 7 +
                                        1,
                                    (term.end.difference(term.start).inDays / 7)
                                        .ceil(),
                                  ),
                                  style: TextStyle(
                                    color: t.mint.ink.withValues(alpha: 0.85),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  SectionLabel(l10n.countdownUpcoming),
                  Card(
                    color: scheme.surfaceContainerLow,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final (i, d)
                            in upcoming.skip(1).take(12).indexed) ...[
                          if (i > 0)
                            Divider(height: 1, color: scheme.outlineVariant),
                          ListTile(
                            title: Text(
                              d.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Text(range(d)),
                            trailing: Text(
                              until(d),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
