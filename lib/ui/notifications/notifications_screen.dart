import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../core/theme.dart';
import '../courses/course_detail_screen.dart';
import '../courses/forum_screen.dart';
import '../courses/module_screen.dart';
import '../core/widgets.dart';
import 'mail_compose_screen.dart';
import '../../l10n/l10n.dart';

/// Opens an eCourse2 link on its page in the app when there is one, and on
/// eCourse2 otherwise. [show] takes the page instead of pushing it, such as
/// into the pane beside a list.
Future<void> openEcourseLink(
  BuildContext context,
  String url, {
  String? title,
  ValueChanged<Widget>? show,
}) async {
  final uri = Uri.parse(url);
  final id = int.tryParse(uri.queryParameters['id'] ?? '');
  final discussion = int.tryParse(uri.queryParameters['d'] ?? '');
  final type = RegExp(r'/mod/(\w+)/view\.php$').firstMatch(uri.path)?[1];
  if (uri.path.endsWith('/mod/forum/discuss.php') && discussion != null) {
    // The discussion page loads by its id alone; the course is not used.
    if (show != null) {
      show(DiscussionScreen(discussionId: discussion, title: title));
    } else {
      context.push('/courses/0/discussions/$discussion', extra: title);
    }
  } else if (uri.path.endsWith('/course/view.php') && id != null) {
    if (show != null) {
      show(CourseDetailScreen(courseId: id));
    } else {
      context.push('/courses/$id');
    }
  } else if (id != null && moduleTypesWithPage.contains(type)) {
    final int course;
    try {
      course = await context.read<EcourseRepository>().courseOfModule(id);
    } on Exception {
      openExternal(url);
      return;
    }
    if (!context.mounted) return;
    if (show != null) {
      show(ModuleScreen(courseId: course, cmid: id, title: title));
    } else {
      context.push('/courses/$course/modules/$id');
    }
  } else {
    openExternal(url);
  }
}

enum _Kind { mail, forum, assignment, notice }

enum _Filter { all, unread, mail, forum, assignment }

typedef _Item = ({
  _Kind kind,
  String title,
  String detail,
  DateTime time,
  bool unread,
  bool selected,
  VoidCallback? onTap,
});

/// The 訊息 tab (design/round-11 messages-tab-variants B): eCourse2's
/// notifications and mail in one list, unread first, each marked by kind.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  /// Bumped after reading a message, so its unread mark updates.
  var _version = 0;
  var _filter = _Filter.all;

  /// What is shown beside the list in a wide window: a mail id or a
  /// notification link, and its page. Mail read there shows as read
  /// without reloading the list.
  Object? _open;
  Widget? _page;
  final _read = <int>{};

  bool get _wide => MediaQuery.sizeOf(context).width >= splitLayout;

  void _show(Object key, Widget page) => setState(() {
    _open = key;
    _page = page;
  });

  /// One page per filter, swiped like the timetable's days.
  final _pages = PageController();

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _pick(_Filter f) => _pages.animateToPage(
    f.index,
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutQuart,
  );

  Future<void> _openMail(int id) async {
    if (_wide) {
      _read.add(id);
      _show(
        id,
        MailScreen(
          id: id,
          onUnread: () => setState(() {
            _read.remove(id);
            _open = null;
            _version++;
          }),
        ),
      );
      return;
    }
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => MailScreen(id: id)));
    if (mounted) setState(() => _version++);
  }

  /// Forum posts and assignment comments and grades reach eCourse2's
  /// notifications from these parts.
  static _Kind _kindOf(String component) => switch (component) {
    'mod_forum' => _Kind.forum,
    'mod_assign' || 'assignsubmission_comments' => _Kind.assignment,
    _ => _Kind.notice,
  };

  static bool _shows(_Filter filter, _Item i) => switch (filter) {
    _Filter.all => true,
    _Filter.unread => i.unread,
    _Filter.mail => i.kind == _Kind.mail,
    _Filter.forum => i.kind == _Kind.forum,
    _Filter.assignment => i.kind == _Kind.assignment,
  };

  /// A new mail; beside the list it opens over an empty pane, so closing
  /// it leaves the pane empty.
  void _compose() {
    if (!_wide) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const MailComposeScreen()));
      return;
    }
    _show(_composeKey, const MailComposeScreen());
  }

  static const _composeKey = 'compose';

  @override
  Widget build(BuildContext context) {
    if (!_wide) return _feed(context);
    final page = _page;
    final outline = Theme.of(context).colorScheme.outlineVariant;
    final detail = _open == null || page == null
        ? const SizedBox.shrink()
        // Its own navigator, so replying opens in this pane.
        : PaneSize(
            child: Navigator(
              key: ValueKey(_open),
              onGenerateInitialRoutes: (_, _) => [
                if (_open == _composeKey)
                  MaterialPageRoute(builder: (_) => const SizedBox.shrink()),
                MaterialPageRoute(builder: (_) => page),
              ],
            ),
          );
    // Half-open on a table: the mail above the fold, the list below it
    // (design/round-11 fold-variants B).
    if (foldOf(context) case (posture: FoldPosture.tabletop, :final at)) {
      return Column(
        children: [
          SizedBox(
            height: at,
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: detail,
            ),
          ),
          Divider(height: 1, color: outline),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: PaneSize(child: _feed(context)),
            ),
          ),
        ],
      );
    }
    // Desktop direction A: the list, and the open mail beside it.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: listWidthOf(context),
          child: PaneSize(child: _feed(context)),
        ),
        VerticalDivider(width: 1, color: outline),
        Expanded(child: detail),
      ],
    );
  }

  Widget _feed(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    final l10n = context.l10n;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: topBar(
        l10n.navMessages,
        // Beside the mail pane, 寫信 sits in the bar instead of floating.
        actions: [
          if (_wide)
            Padding(
              padding: const EdgeInsets.only(right: Space.l),
              child: IconButton(
                tooltip: l10n.compose,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainer,
                ),
                onPressed: _compose,
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
        ],
        bottom: ChipBar(
          children: [
            for (final (f, label) in [
              (_Filter.all, l10n.viewAll),
              (_Filter.unread, l10n.unread),
              (_Filter.mail, l10n.mail),
              (_Filter.forum, l10n.msgForum),
              (_Filter.assignment, l10n.msgAssignment),
            ])
              BarChip(
                label: label,
                selected: _filter == f,
                tone: context.tones.sun,
                onTap: () => _pick(f),
              ),
          ],
        ),
      ),
      floatingActionButton: _wide
          ? null
          : Padding(
              // Clear the floating nav bar.
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom,
              ),
              child: FloatingActionButton.extended(
                onPressed: _compose,
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.compose),
              ),
            ),
      body: Loader.watch(
        key: ValueKey(_version),
        watch: () => repo.watch(
          (repo) async => (
            notices: await repo.notices(),
            mail: await repo.inbox(),
            courses: await repo.mailCourses(),
          ),
        ),
        builder: (context, d) {
          final names = {for (final c in d.courses) c.id: c.name};
          final all = <_Item>[
            for (final m in d.mail)
              (
                kind: _Kind.mail,
                title: m.subject,
                detail: '${m.sender}・${names[m.courseId] ?? m.course}',
                time: m.time,
                unread: m.unread && !_read.contains(m.id),
                selected: m.id == _open,
                onTap: () => _openMail(m.id),
              ),
            for (final n in d.notices)
              (
                kind: _kindOf(n.component),
                title: n.subject,
                detail: n.text,
                time: n.time,
                unread: !n.read,
                selected: n.url != null && n.url == _open,
                onTap: n.url == null
                    ? null
                    : () => openEcourseLink(
                        context,
                        n.url!,
                        title: n.subject,
                        show: _wide ? (page) => _show(n.url!, page) : null,
                      ),
              ),
          ]..sort((a, b) => b.time.compareTo(a.time));
          return PageView(
            // Keeps the page when the list reloads after reading mail.
            key: const PageStorageKey('messages'),
            controller: _pages,
            // A chip lighting up ticks, however it was reached.
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _filter = _Filter.values[i]);
            },
            children: [
              for (final f in _Filter.values)
                _list(context, [
                  for (final i in all)
                    if (_shows(f, i)) i,
                ]),
            ],
          );
        },
      ),
    );
  }

  Widget _list(BuildContext context, List<_Item> shown) {
    final l10n = context.l10n;
    final unread = shown.where((i) => i.unread).toList();
    final earlier = shown.where((i) => !i.unread).toList();
    return ListView(
      // Room for the 寫信 button over the last message.
      // The list opens with a section label, which brings its own gap.
      padding: scrollPadding(
        context,
        top: 0,
      ).copyWith(bottom: scrollPadding(context).bottom + (_wide ? 0 : 72)),
      children: [
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Center(
              child: Text(
                l10n.noNotifications,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        for (final (label, items) in [
          (l10n.unread, unread),
          (l10n.earlier, earlier),
        ])
          if (items.isNotEmpty) ...[
            SectionLabel(label),
            for (final (i, item) in items.indexed) ...[
              if (i > 0) const Divider(height: 1),
              _MessageRow(item: item),
            ],
          ],
      ],
    );
  }
}

/// A kind square, the title and who or what it is from, and when.
class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.item});

  final _Item item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = context.tones;
    final (tone, icon) = switch (item.kind) {
      _Kind.mail => (t.sun, Icons.mail_outline),
      _Kind.forum => (t.lilac, Icons.forum_outlined),
      _Kind.assignment => (t.peach, Icons.assignment_outlined),
      _Kind.notice => (
        Tone(
          scheme.surfaceContainerHigh,
          scheme.onSurfaceVariant,
          scheme.onSurfaceVariant,
        ),
        Icons.notifications_none,
      ),
    };
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: item.selected ? scheme.surfaceContainerHigh : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.xs,
            vertical: Space.m,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tone.fill,
                  borderRadius: BorderRadius.circular(Corners.small),
                ),
                child: Icon(icon, size: 20, color: tone.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: item.unread
                            ? FontWeight.w900
                            : FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    if (item.detail.isNotEmpty)
                      Text(
                        item.detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateTimeLabel(context, item.time),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: item.unread ? t.sun.strong : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One message, read in the app; opening it marks it read on eCourse2.
/// Replying and forwarding happen on eCourse2's page for the message.
class MailScreen extends StatelessWidget {
  const MailScreen({super.key, required this.id, this.onUnread});

  final int id;

  /// After marking it unread; closes the page when not given.
  final VoidCallback? onUnread;

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
              if (onUnread != null) {
                onUnread!();
              } else if (context.mounted) {
                Navigator.of(context).pop();
              }
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
                Space.s,
                pageMargin,
                MediaQuery.paddingOf(context).bottom + Space.s,
              ),
              // A pill under the text beside the list; the full width on a
              // phone.
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  width: onUnread != null ? null : double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MailComposeScreen(replyTo: id, replyName: m.sender),
                      ),
                    ),
                    child: Text(l10n.reply),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
