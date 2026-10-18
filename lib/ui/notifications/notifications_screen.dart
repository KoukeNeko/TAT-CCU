import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: _Bar(),
        body: TabBarView(children: [_Notices(), _Mail()]),
      ),
    );
  }
}

class _Bar extends StatelessWidget implements PreferredSizeWidget {
  const _Bar();

  @override
  Size get preferredSize => const Size.fromHeight(76 + 56);

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.sun;
    return topBar(
      '通知',
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: ShapeDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              shape: const StadiumBorder(),
            ),
            child: TabBar(
              indicator: ShapeDecoration(
                color: tone.fill,
                shape: const StadiumBorder(),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: tone.ink,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900),
              tabs: const [
                Tab(text: '通知'),
                Tab(text: '信件'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Notices extends StatelessWidget {
  const _Notices();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Loader<List<NoticeItem>>(
      load: repo.notices,
      builder: (context, items) {
        if (items.isEmpty) return const EmptyState('沒有通知');
        return ListView.separated(
          padding: scrollPadding(context, top: 16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final n = items[i];
            return _Row(
              unread: !n.read,
              title: n.subject,
              subtitle: dateTimeLabel(n.time),
              onTap: n.url == null ? null : () => openExternal(n.url!),
            );
          },
        );
      },
    );
  }
}

class _Mail extends StatelessWidget {
  const _Mail();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Loader<List<MailItem>>(
      load: repo.inbox,
      builder: (context, items) {
        if (items.isEmpty) return const EmptyState('沒有信件');
        return ListView.separated(
          padding: scrollPadding(context, top: 16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final m = items[i];
            return _Row(
              unread: m.unread,
              title: m.subject,
              subtitle: '${m.sender}・${m.course}・${dateTimeLabel(m.time)}',
            );
          },
        );
      },
    );
  }
}

/// Unread rows sit on the sun block; read rows fall back to plain surface.
class _Row extends StatelessWidget {
  const _Row({
    required this.unread,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final bool unread;
  final String title, subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sun = context.tones.sun;
    final tone = unread
        ? sun
        : Tone(scheme.surfaceContainerLow, scheme.onSurface, scheme.primary);
    return ToneBlock(
      tone: tone,
      radius: 24,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 12),
            child: Container(
              width: 10,
              height: 10,
              decoration: ShapeDecoration(
                color: unread ? sun.strong : Colors.transparent,
                shape: const CookieBorder(lobes: 6, depth: 0.15),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: unread ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
