import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../data/services/ecourse_web.dart';
import '../core/campus_web_screen.dart';
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

/// eCourse2 mail (local_mail 1.x): read here, written on eCourse2's own
/// pages, since the plugin offers apps no way to send.
const _mailPages = 'https://$ecourseHost/local/mail';

class _Mail extends StatefulWidget {
  const _Mail();

  @override
  State<_Mail> createState() => _MailState();
}

class _MailState extends State<_Mail> {
  /// Bumped after reading a message, so its unread mark updates.
  var _version = 0;

  /// The course chip picked; null for all mail.
  int? _course;

  Future<void> _open(MailItem m) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => MailScreen(id: m.id)));
    if (mounted) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    final sun = context.tones.sun;
    return Stack(
      children: [
        Loader.watch(
          key: ValueKey(_version),
          watch: () => repo.watch(
            (repo) async =>
                (items: await repo.inbox(), courses: await repo.mailCourses()),
          ),
          builder: (context, d) {
            final names = {for (final c in d.courses) c.id: c.name};
            final shown = [
              for (final m in d.items)
                if (_course == null || m.courseId == _course) m,
            ];
            return ListView(
              // Room for the 寫信 button over the last message.
              padding: scrollPadding(context)
                  .copyWith(bottom: scrollPadding(context).bottom + 72),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (id, label) in [
                        (null, context.l10n.viewAll),
                        for (final c in d.courses)
                          if (d.items.any((m) => m.courseId == c.id))
                            (
                              c.id,
                              c.unread > 0 ? '${c.name} ${c.unread}' : c.name,
                            ),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: BarChip(
                            label: label,
                            selected: _course == id,
                            tone: sun,
                            onTap: () => setState(() => _course = id),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(
                      child: Text(
                        context.l10n.noMail,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                for (final m in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _Row(
                      unread: m.unread,
                      title: m.subject,
                      subtitle:
                          '${m.sender}・${names[m.courseId] ?? m.course}・${dateTimeLabel(context, m.time)}',
                      onTap: () => _open(m),
                    ),
                  ),
              ],
            );
          },
        ),
        Positioned(
          right: pageMargin,
          bottom: MediaQuery.paddingOf(context).bottom + 16,
          child: FloatingActionButton.extended(
            onPressed: () => openCampusPage(
              context,
              '$_mailPages/create.php',
              context.l10n.compose,
            ),
            icon: const Icon(Icons.edit_outlined),
            label: Text(context.l10n.compose),
          ),
        ),
      ],
    );
  }
}

/// One message, read in the app; opening it marks it read on eCourse2.
/// Replying and forwarding happen on eCourse2's page for the message.
class MailScreen extends StatelessWidget {
  const MailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(
        context,
        '',
        action: IconButton(
          tooltip: l10n.markUnread,
          icon: const Icon(Icons.mark_email_unread_outlined),
          onPressed: () async {
            try {
              await repo.markMailUnread(id);
              if (context.mounted) Navigator.of(context).pop();
            } catch (e) {
              if (context.mounted) showSendError(context, e);
            }
          },
        ),
      ),
      body: Loader.watch(
        watch: () => repo.watch((repo) => repo.mailMessage(id)),
        builder: (context, m) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: scrollPadding(context).copyWith(bottom: 16),
                children: [
                  Text(
                    m.course,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    m.subject,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${m.sender}・${dateTimeLabel(context, m.time)}',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    m.body,
                    style: const TextStyle(fontSize: 15, height: 1.7),
                  ),
                  if (m.attachments.isNotEmpty) ...[
                    SectionLabel(l10n.attachments),
                    FileList(
                      files: m.attachments,
                      detail: (f) => fileSize(f.size),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                pageMargin,
                8,
                pageMargin,
                MediaQuery.paddingOf(context).bottom + 8,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => openCampusPage(
                    context,
                    '$_mailPages/view.php?t=inbox&m=$id',
                    l10n.reply,
                  ),
                  child: Text(l10n.reply),
                ),
              ),
            ),
          ],
        ),
      ),
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
