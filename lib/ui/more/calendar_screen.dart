import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// Upcoming dated events for the next 30 days, grouped by day.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Scaffold(
      appBar: subBar(context, '行事曆'),
      body: Loader<List<DueItem>>(
        load: () => repo.dueSoon(days: 30),
        builder: (context, items) {
          if (items.isEmpty) return const EmptyState('30 天內沒有事件');
          final days = <DateTime, List<DueItem>>{};
          for (final e in items) {
            final d = DateTime(e.due.year, e.due.month, e.due.day);
            days.putIfAbsent(d, () => []).add(e);
          }
          final tones = context.tones;
          return ListView(
            padding: scrollPadding(context, top: 4),
            children: [
              for (final entry in days.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CookieBadge(
                        value: '${entry.key.day}',
                        unit: weekdayNames[entry.key.weekday - 1],
                        color: tones.mint.fill,
                        ink: tones.mint.ink,
                        size: 64,
                        shape: scallop,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            for (final e in entry.value)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ToneBlock(
                                  tone: tones.forCourse(e.courseId),
                                  radius: 22,
                                  padding: const EdgeInsets.all(14),
                                  onTap: e.url == null
                                      ? null
                                      : () => openExternal(e.url!),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        '${clock(e.due.hour * 60 + e.due.minute)}・${e.course}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
