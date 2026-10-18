import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// Assignments, quizzes and other dated activities in the next two weeks.
class DueScreen extends StatelessWidget {
  const DueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, '待辦'),
      body: Loader<List<DueItem>>(
        load: () => repo.dueSoon(),
        builder: (context, items) {
          if (items.isEmpty) return const EmptyState('14 天內沒有到期項目');
          return ListView.separated(
            padding: scrollPadding(context),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => DueBlock(item: items[i]),
          );
        },
      ),
    );
  }
}

/// One dated activity; the countdown cookie turns peach within 2 days.
class DueBlock extends StatelessWidget {
  const DueBlock({super.key, required this.item});

  final DueItem item;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final left = item.due.difference(DateTime.now());
    final urgent = left.inHours < 48;
    final tone = urgent ? tones.peach : tones.forCourse(item.courseId);
    final value = left.inHours < 24 ? '${left.inHours}' : '${left.inDays}';
    final unit = left.inHours < 24 ? '小時' : '天';
    return ToneBlock(
      tone: tone,
      padding: const EdgeInsets.all(14),
      onTap: item.url == null ? null : () => openExternal(item.url!),
      child: Row(
        children: [
          CookieBadge(
            value: value,
            unit: unit,
            color: tone.strong,
            ink: tone.fill,
            size: 64,
            shape: spikyStar,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.course,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  dateTimeLabel(item.due),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
