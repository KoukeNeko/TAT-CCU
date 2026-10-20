import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../core/theme.dart';
import '../courses/module_screen.dart';
import '../core/widgets.dart';
import '../../l10n/l10n.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _Bar(),
        body: TabBarView(children: [_Notices(), _Mail()]),
      ),
    );
  }
}

/// Opens an eCourse2 link on its page in the app when there is one, and on
/// eCourse2 otherwise.
Future<void> openEcourseLink(
  BuildContext context,
  String url, {
  String? title,
}) async {
  final uri = Uri.parse(url);
  final id = int.tryParse(uri.queryParameters['id'] ?? '');
  final discussion = int.tryParse(uri.queryParameters['d'] ?? '');
  final type = RegExp(r'/mod/(\w+)/view\.php$').firstMatch(uri.path)?[1];
  if (uri.path.endsWith('/mod/forum/discuss.php') && discussion != null) {
    // The discussion page loads by its id alone; the course is not used.
    context.push('/courses/0/discussions/$discussion', extra: title);
  } else if (uri.path.endsWith('/course/view.php') && id != null) {
    context.push('/courses/$id');
  } else if (id != null && moduleTypesWithPage.contains(type)) {
    final int course;
    try {
      course = await context.read<EcourseRepository>().courseOfModule(id);
    } on Exception {
      openExternal(url);
      return;
    }
    if (context.mounted) context.push('/courses/$course/modules/$id');
  } else {
    openExternal(url);
  }
}

class _Bar extends StatelessWidget implements PreferredSizeWidget {
  const _Bar();

  @override
  Size get preferredSize => const Size.fromHeight(72 + 52);

  @override
  Widget build(BuildContext context) {
    final tabs = DefaultTabController.of(context);
    return subBar(
      context,
      context.l10n.notifications,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: AnimatedBuilder(
          animation: tabs,
          builder: (context, _) => ChipBar(
            children: [
              for (final (i, label) in [
                context.l10n.notifications,
                context.l10n.mail,
              ].indexed)
                BarChip(
                  label: label,
                  selected: tabs.index == i,
                  tone: context.tones.sun,
                  onTap: () => tabs.animateTo(i),
                ),
            ],
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
    return Loader<List<NoticeItem>>.watch(
      watch: () => repo.watch((repo) => repo.notices()),
      builder: (context, items) {
        if (items.isEmpty) return EmptyState(context.l10n.noNotifications);
        return ListView.separated(
          padding: scrollPadding(context),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final n = items[i];
            return _Row(
              unread: !n.read,
              title: n.subject,
              subtitle: dateTimeLabel(context, n.time),
              onTap: n.url == null
                  ? null
                  : () => openEcourseLink(context, n.url!, title: n.subject),
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
    return Loader<List<MailItem>>.watch(
      watch: () => repo.watch((repo) => repo.inbox()),
      builder: (context, items) {
        if (items.isEmpty) return EmptyState(context.l10n.noMail);
        return ListView.separated(
          padding: scrollPadding(context),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final m = items[i];
            return _Row(
              unread: m.unread,
              title: m.subject,
              subtitle:
                  '${m.sender}・${m.course}・${dateTimeLabel(context, m.time)}',
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
      radius: Corners.row,
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
