import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../core/pair_switch.dart';
import '../core/theme.dart';
import '../courses/course_detail_screen.dart';
import '../courses/forum_screen.dart';
import '../courses/module_screen.dart';
import '../core/widgets.dart';
import 'mail_compose_screen.dart';
import '../../l10n/l10n.dart';

/// Marks a notification read on eCourse2 as it is opened. Offline it stays
/// unread there and shows so on the next read.
void markNoticeRead(BuildContext context, int id) => unawaited(
  context
      .read<EcourseRepository>()
      .markNoticeRead(id)
      .catchError((Object e) => debugPrint('mark read: $e')),
);

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

enum _Kind { mail, sent, forum, assignment, notice }

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
  var _filter = _Filter.all;

  /// 信件 shows what was sent instead of the inbox (design/round-17 A).
  var _sentBox = false;

  /// What is shown beside the list in a wide window: a mail id or a
  /// notification link, and its page.
  Object? _open;
  Widget? _page;

  /// Mail read or marked unread here, by id: whether it is unread now.
  /// The list keeps what it shows instead of loading again from scratch.
  final _unread = <int, bool>{};

  /// Notifications opened here, read now whatever the list last said.
  final _seen = <int>{};

  bool get _wide => listBeside(context);

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

  Future<void> _openMail(int id, {bool sent = false}) async {
    if (sent) {
      if (_wide) return _show(id, MailScreen(id: id, sent: true));
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => MailScreen(id: id, sent: true)),
      );
      return;
    }
    setState(() => _unread[id] = false);
    final repo = context.read<EcourseRepository>();
    // Offline it stays unread on eCourse2 and shows so on the next read.
    unawaited(
      repo
          .markMailRead(id)
          .catchError((Object e) => debugPrint('mark read: $e')),
    );
    if (_wide) {
      _show(
        id,
        MailScreen(
          id: id,
          onUnread: () => setState(() {
            _unread[id] = true;
            _open = null;
          }),
        ),
      );
      return;
    }
    final markedUnread = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => MailScreen(id: id)));
    if (markedUnread == true && mounted) setState(() => _unread[id] = true);
  }

  /// Forum posts and assignment comments and grades reach eCourse2's
  /// notifications from these parts.
  static _Kind _kindOf(String component) => switch (component) {
    'mod_forum' => _Kind.forum,
    'mod_assign' || 'assignsubmission_comments' => _Kind.assignment,
    _ => _Kind.notice,
  };

  /// Sent mail shows only in 信件, switched to 寄件備份.
  bool _shows(_Filter filter, _Item i) => switch (filter) {
    _Filter.all => i.kind != _Kind.sent,
    _Filter.unread => i.unread,
    _Filter.mail => i.kind == (_sentBox ? _Kind.sent : _Kind.mail),
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
        watch: () => repo.watch(
          (repo) async => (
            notices: await repo.notices(),
            mail: await repo.inbox(),
            sent: await repo.sent(),
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
                unread: _unread[m.id] ?? m.unread,
                selected: m.id == _open,
                onTap: () => _openMail(m.id),
              ),
            for (final m in d.sent)
              (
                kind: _Kind.sent,
                title: m.subject,
                detail: '${l10n.mailTo(m.to)}・${names[m.courseId] ?? m.course}',
                time: m.time,
                unread: false,
                selected: m.id == _open,
                onTap: () => _openMail(m.id, sent: true),
              ),
            for (final n in d.notices)
              (
                kind: _kindOf(n.component),
                title: n.subject,
                detail: n.text,
                time: n.time,
                unread: !n.read && !_seen.contains(n.id),
                selected: n.url != null && n.url == _open,
                onTap: n.url == null
                    ? null
                    : () {
                        if (!n.read) {
                          setState(() => _seen.add(n.id));
                          markNoticeRead(context, n.id);
                        }
                        openEcourseLink(
                          context,
                          n.url!,
                          title: n.subject,
                          show: _wide ? (page) => _show(n.url!, page) : null,
                        );
                      },
              ),
          ]..sort((a, b) => b.time.compareTo(a.time));
          return PageView(
            // Keeps the chosen filter page when the list updates.
            key: const PageStorageKey('messages'),
            controller: _pages,
            // A chip lighting up ticks, however it was reached.
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _filter = _Filter.values[i]);
            },
            children: [
              for (final f in _Filter.values)
                _list(
                  context,
                  [
                    for (final i in all)
                      if (_shows(f, i)) i,
                  ],
                  empty: f == _Filter.mail && _sentBox
                      ? l10n.noSentMail
                      : l10n.noNotifications,
                  header: f == _Filter.mail
                      ? Padding(
                          padding: const EdgeInsets.only(top: Space.m),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: PairSwitch(
                              labels: (l10n.inbox, l10n.sentMail),
                              second: _sentBox,
                              tone: context.tones.sun,
                              segment: 88,
                              onChanged: (sent) =>
                                  setState(() => _sentBox = sent),
                            ),
                          ),
                        )
                      : null,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _list(
    BuildContext context,
    List<_Item> shown, {
    required String empty,
    Widget? header,
  }) {
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
        ?header,
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Center(
              child: Text(
                empty,
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

/// What this account sent, on its own page: opened from 寫信 when a send
/// went unconfirmed, so the letter being written stays behind it.
class SentMailScreen extends StatelessWidget {
  const SentMailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    final l10n = context.l10n;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, l10n.sentMail),
      body: Loader.watch(
        watch: () => repo.watch((repo) => repo.sent()),
        builder: (context, sent) => ListView(
          padding: scrollPadding(context),
          children: [
            if (sent.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Center(
                  child: Text(
                    l10n.noSentMail,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            for (final (i, m) in sent.indexed) ...[
              if (i > 0) const Divider(height: 1),
              _MessageRow(
                item: (
                  kind: _Kind.sent,
                  title: m.subject,
                  detail: l10n.mailTo(m.to),
                  time: m.time,
                  unread: false,
                  selected: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MailScreen(id: m.id, sent: true),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
      // Grey, so sent rows read apart from received ones (round-17 A).
      _Kind.sent => (
        Tone(scheme.surfaceContainerHigh, t.sun.strong, t.sun.strong),
        Icons.send_outlined,
      ),
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
  const MailScreen({
    super.key,
    required this.id,
    this.onUnread,
    this.sent = false,
  });

  final int id;

  /// One this account sent: who it went to, and nothing to mark or reply.
  final bool sent;

  /// After marking it unread; when not given, the page closes with true.
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
        action: sent
            ? null
            : IconButton(
                tooltip: l10n.markUnread,
                icon: const Icon(Icons.mark_email_unread_outlined),
                onPressed: () async {
                  try {
                    await repo.markMailUnread(id);
                    if (onUnread != null) {
                      onUnread!();
                    } else if (context.mounted) {
                      Navigator.of(context).pop(true);
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
                // The reply bar below takes the bottom inset, when there is one.
                padding: sent
                    ? scrollPadding(context)
                    : scrollPadding(context).copyWith(bottom: 16),
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
                    '${sent ? l10n.mailTo(m.to) : m.sender}・'
                    '${dateTimeLabel(context, m.time)}',
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
            if (!sent)
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
                          builder: (_) => MailComposeScreen(
                            replyTo: id,
                            replyName: m.sender,
                          ),
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
