import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:clock/clock.dart' as clk;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../data/services/ecourse_web.dart';
import '../core/campus_session.dart';
import '../core/desk_list.dart';
import '../core/desktop_mode.dart';
import '../core/theme.dart';
import '../courses/course_detail_screen.dart';
import '../courses/forum_screen.dart';
import '../courses/module_screen.dart';
import '../core/widgets.dart';
import 'mail_compose_screen.dart';
import '../../l10n/l10n.dart';
import '../core/segment_switch.dart';
import '../core/glass_dialog.dart';

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
      context.push('/messages/discussions/$discussion', extra: title);
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

/// A draft can be saved before it has a subject or anyone to go to.
String _subject(AppLocalizations l10n, String subject) =>
    subject.isEmpty ? l10n.noSubject : subject;

String _to(AppLocalizations l10n, String to) =>
    to.isEmpty ? '' : l10n.mailTo(to);

enum _Kind { mail, sent, draft, forum, assignment, notice }

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

  /// The mail folder 信件 shows (design/round-20 B).
  var _folder = MailFolder.inbox;

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

  Future<void> _openMail(int id, MailFolder folder) async {
    void gone() => setState(() => _open = null);
    if (folder == MailFolder.sent || folder == MailFolder.drafts) {
      final page = MailScreen(
        id: id,
        folder: folder,
        onGone: _wide ? gone : null,
      );
      if (_wide) return _show(id, page);
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => page));
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
          folder: folder,
          onUnread: () => setState(() {
            _unread[id] = true;
            _open = null;
          }),
          onGone: gone,
        ),
      );
      return;
    }
    final markedUnread = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MailScreen(id: id, folder: folder),
      ),
    );
    if (markedUnread == true && mounted) setState(() => _unread[id] = true);
  }

  /// Forum posts and assignment comments and grades reach eCourse2's
  /// notifications from these parts.
  static _Kind _kindOf(String component) => switch (component) {
    'mod_forum' => _Kind.forum,
    'mod_assign' || 'assignsubmission_comments' => _Kind.assignment,
    _ => _Kind.notice,
  };

  /// 信件 lists its chosen folder instead, from its own rows.
  bool _shows(_Filter filter, _Item i) => switch (filter) {
    _Filter.all => true,
    _Filter.unread => i.unread,
    _Filter.mail => false,
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
        ? const EmptyPane()
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
          child: LeadingPane(child: PaneSize(child: _feed(context))),
        ),
        VerticalDivider(width: 1, color: outline),
        Expanded(child: detail),
      ],
    );
  }

  Widget _feed(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    final l10n = context.l10n;
    // Beside the mail pane, and on a flip phone's outer display, 寫信 sits
    // in the bar instead of floating.
    final inBar = _wide || coverScreen(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: topBar(
        l10n.navMessages,
        actions: [
          if (inBar)
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
      floatingActionButton: inBar
          ? null
          : Padding(
              // Clear the floating nav bar.
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom,
              ),
              child: FloatingAction(
                onPressed: _compose,
                icon: Icons.edit_outlined,
                label: l10n.compose,
              ),
            ),
      body: Loader.watch(
        watch: () => repo.watch(
          (repo) async => (
            notices: await repo.notices(),
            folders: {
              for (final (i, mail) in (await Future.wait([
                for (final f in MailFolder.values) repo.mailFolder(f),
              ])).indexed)
                MailFolder.values[i]: mail,
            },
            courses: await repo.mailCourses(),
          ),
        ),
        refreshOn: mailChanged,
        builder: (context, d) {
          final names = {for (final c in d.courses) c.id: c.name};
          _Item mailRow(MailItem m, MailFolder folder) {
            final mine =
                folder == MailFolder.sent || folder == MailFolder.drafts;
            return (
              kind: switch (folder) {
                MailFolder.sent => _Kind.sent,
                MailFolder.drafts => _Kind.draft,
                _ => _Kind.mail,
              },
              title: _subject(l10n, m.subject),
              detail: [
                mine ? _to(l10n, m.to) : m.sender,
                names[m.courseId] ?? m.course,
              ].where((s) => s.isNotEmpty).join('・'),
              time: m.time,
              unread: !mine && (_unread[m.id] ?? m.unread),
              selected: m.id == _open,
              onTap: () => _openMail(m.id, folder),
            );
          }

          final mail = [
            for (final m in d.folders[_folder]!) mailRow(m, _folder),
          ]..sort((a, b) => b.time.compareTo(a.time));
          final all = <_Item>[
            for (final m in d.folders[MailFolder.inbox]!)
              mailRow(m, MailFolder.inbox),
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
                if (f == _Filter.mail)
                  _mailPage(context, mail)
                else
                  _list(context, [
                    for (final i in all)
                      if (_shows(f, i)) i,
                  ], empty: l10n.noNotifications),
            ],
          );
        },
      ),
    );
  }

  /// The chosen folder under its five, as on eCourse2, which float over
  /// the list; the trash, when it has mail, can be emptied.
  Widget _mailPage(BuildContext context, List<_Item> shown) {
    final l10n = context.l10n;
    final pad = scrollPadding(context, top: 0);
    return Stack(
      children: [
        _list(
          context,
          shown,
          empty: l10n.noMail,
          // Room for the folders above the first row.
          header: Padding(
            padding: const EdgeInsets.only(top: Space.m + 40),
            child: _folder == MailFolder.trash && shown.isNotEmpty
                ? Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Padding(
                      padding: const EdgeInsets.only(top: Space.s),
                      child: TextButton(
                        onPressed: _emptyTrash,
                        child: Text(l10n.emptyTrash),
                      ),
                    ),
                  )
                : null,
          ),
        ),
        Positioned(
          top: pad.top + Space.m,
          left: pad.left,
          right: pad.right,
          child: SegmentSwitch(
            labels: [
              l10n.folderInbox,
              l10n.folderStarred,
              l10n.folderDrafts,
              l10n.folderSent,
              l10n.folderTrash,
            ],
            selected: _folder.index,
            tone: context.tones.sun,
            onChanged: (i) => setState(() => _folder = MailFolder.values[i]),
            floating: true,
          ),
        ),
      ],
    );
  }

  Future<void> _emptyTrash() async {
    final l10n = context.l10n;
    final ok = await showGlassDialog<bool>(
      context: context,
      builder: (context) => GlassDialog(
        title: l10n.emptyTrashTitle,
        content: Text(l10n.emptyTrashBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.emptyTrashAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final error = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _EmptyTrashScreen()),
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      mailChanged.value++;
    }
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
    if (desktopUi(context)) {
      return ListView(
        padding: EdgeInsets.only(top: scrollPadding(context, top: 0).top),
        children: [
          ?header,
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Center(child: Text(empty)),
            ),
          for (final (label, items) in [
            (l10n.unread, unread),
            (l10n.earlier, earlier),
          ])
            if (items.isNotEmpty) ...[
              DeskGroup(label, trailing: Text('${items.length}')),
              for (final item in items) _MessageRow(item: item),
            ],
        ],
      );
    }
    return ListView(
      // Room for the 寫信 button over the last message.
      // The list opens with a section label, which brings its own gap.
      padding: scrollPadding(context, top: 0).copyWith(
        bottom:
            scrollPadding(context).bottom +
            (_wide || coverScreen(context) ? 0 : 72),
      ),
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
                  title: _subject(l10n, m.subject),
                  detail: _to(l10n, m.to),
                  time: m.time,
                  unread: false,
                  selected: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          MailScreen(id: m.id, folder: MailFolder.sent),
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
      _Kind.draft => (
        Tone(scheme.surfaceContainerHigh, t.sun.strong, t.sun.strong),
        Icons.edit_outlined,
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
    if (desktopUi(context)) {
      final now = clk.clock.now();
      final today = DateUtils.isSameDay(item.time, now);
      return DeskRow(
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 15, color: tone.strong),
        ),
        title: item.title,
        subtitle: item.detail.isEmpty ? null : item.detail,
        dimmed: !item.unread,
        selected: item.selected,
        onTap: item.onTap,
        trailing: Text(
          today
              ? clock(item.time.hour * 60 + item.time.minute)
              : monthDay(item.time),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: item.unread ? t.sun.strong : scheme.onSurfaceVariant,
          ),
        ),
      );
    }
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

/// Empties the trash on eCourse2's mail pages, showing the sign-in steps
/// meanwhile; closes with null when done, or the error.
class _EmptyTrashScreen extends StatelessWidget {
  const _EmptyTrashScreen();

  @override
  Widget build(BuildContext context) => CampusSession(
    title: context.l10n.emptyTrash,
    entry: ecourseEntry,
    host: ecourseHost,
    script: () => mailAction(MailAction.emptyTrash),
    onMessage: (message) => Navigator.of(context).pop(
      message['ok'] == true
          ? null
          : '${message['error'] ?? context.l10n.sendFailed}',
    ),
    child: null,
  );
}

/// One message, read in the app; opening it marks it read on eCourse2.
/// Starring, the trash and discarding a draft go through eCourse2's mail
/// pages in a signed-in page behind the message ([mailAction]).
class MailScreen extends StatefulWidget {
  const MailScreen({
    super.key,
    required this.id,
    this.folder = MailFolder.inbox,
    this.onUnread,
    this.onGone,
  });

  final int id;

  /// Where it was opened from: sent mail has nothing to mark or reply to,
  /// a draft is edited instead, and one in the trash is restored.
  final MailFolder folder;

  /// After marking it unread; when not given, the page closes with true.
  final VoidCallback? onUnread;

  /// After it leaves its folder (deleted, restored or discarded); when not
  /// given, the page closes.
  final VoidCallback? onGone;

  @override
  State<MailScreen> createState() => _MailScreenState();
}

class _MailScreenState extends State<MailScreen> {
  final _session = GlobalKey<CampusSessionState>();

  /// The star as last set here; null until it is.
  bool? _starred;
  MailAction? _running;

  MailFolder get _folder => widget.folder;

  Future<void> _run(MailAction action) async {
    if (action == MailAction.discard) {
      final l10n = context.l10n;
      final ok = await showGlassDialog<bool>(
        context: context,
        builder: (context) => GlassDialog(
          title: l10n.discardDraftTitle,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.discardDraft),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _running = action);
    await _session.currentState?.runSignedIn(
      mailAction(action, folder: _folder.name, id: widget.id),
    );
  }

  void _received(Map<String, dynamic> message, bool starred) {
    final action = _running;
    setState(() => _running = null);
    if (message['ok'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${message['error'] ?? context.l10n.sendFailed}'),
        ),
      );
      return;
    }
    mailChanged.value++;
    if (action == MailAction.star) {
      setState(() => _starred = !starred);
    } else if (widget.onGone != null) {
      widget.onGone!();
    } else {
      Navigator.of(context).pop();
    }
  }

  /// A reply, or the draft carried on; a draft sent leaves the drafts.
  Future<void> _write(MailMessage m) async {
    final draft = _folder == MailFolder.drafts;
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => draft
            ? MailComposeScreen(
                draft: widget.id,
                replyName: m.to,
                subject: m.subject,
                body: m.body,
              )
            : MailComposeScreen(replyTo: widget.id, replyName: m.sender),
      ),
    );
    if (sent != true || !mounted) return;
    mailChanged.value++;
    if (!draft) return;
    if (widget.onGone != null) {
      widget.onGone!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final sent = _folder == MailFolder.sent || _folder == MailFolder.drafts;
    final canReply = _folder != MailFolder.sent && _folder != MailFolder.trash;
    final desk = desktopUi(context);
    return Loader.watch(
      bar: (context) => subBar(context, ''),
      watch: () => repo.watch((repo) => repo.mailMessage(widget.id)),
      builder: (context, m) {
        final starred = _starred ?? m.starred;
        final busy = _running != null;
        IconButton button(String tip, IconData icon, VoidCallback onTap) =>
            IconButton(
              tooltip: tip,
              icon: Icon(icon),
              onPressed: busy ? null : onTap,
            );
        return CampusSession(
          key: _session,
          title: '',
          entry: ecourseEntry,
          host: ecourseHost,
          // Signed in while the message is read, so an action runs at once.
          script: () => ecourseScript("post({ kind: 'ready' });"),
          onMessage: (message) {
            if (message['kind'] == 'mail') _received(message, starred);
          },
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_folder != MailFolder.drafts && _folder != MailFolder.trash)
                button(
                  starred ? l10n.unstarMail : l10n.starMail,
                  starred ? Icons.star_rounded : Icons.star_outline_rounded,
                  () => _run(MailAction.star),
                ),
              if (!sent && _folder != MailFolder.trash)
                button(
                  l10n.markUnread,
                  Icons.mark_email_unread_outlined,
                  () async {
                    try {
                      await repo.markMailUnread(widget.id);
                      if (widget.onUnread != null) {
                        widget.onUnread!();
                      } else if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    } catch (e) {
                      if (context.mounted) showSendError(context, e);
                    }
                  },
                ),
              switch (_folder) {
                MailFolder.drafts => button(
                  l10n.discardDraft,
                  Icons.delete_outline,
                  () => _run(MailAction.discard),
                ),
                MailFolder.trash => button(
                  l10n.restoreMail,
                  Icons.restore_from_trash_outlined,
                  () => _run(MailAction.delete),
                ),
                _ => button(
                  l10n.delete,
                  Icons.delete_outline,
                  () => _run(MailAction.delete),
                ),
              },
            ],
          ),
          // Builder: insets have to come from inside the session's Scaffold,
          // where the glass app bar is part of the top padding.
          child: Builder(
            builder: (context) => Column(
              children: [
                Expanded(
                  child: ListView(
                    // The reply bar below takes the bottom inset, when there
                    // is one.
                    padding: desk
                        // Beside the list, from its edge as in Mail.
                        ? EdgeInsets.fromLTRB(
                            32,
                            scrollPadding(context).top,
                            32,
                            32,
                          )
                        : _folder == MailFolder.sent
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
                        _subject(l10n, m.subject),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          sent ? _to(l10n, m.to) : m.sender,
                          dateTimeLabel(context, m.time),
                        ].where((s) => s.isNotEmpty).join('・'),
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        // A readable line beside the list on a desktop.
                        constraints: BoxConstraints(
                          maxWidth: desk ? 620 : double.infinity,
                        ),
                        child: SelectableText(
                          m.body,
                          style: TextStyle(
                            fontSize: desk ? 14 : 15,
                            height: desk ? 1.75 : 1.7,
                          ),
                        ),
                      ),
                      if (desk && canReply) ...[
                        const SizedBox(height: Space.l),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: DeskButton(
                            icon: Icons.reply,
                            label: _folder == MailFolder.drafts
                                ? l10n.editDraft
                                : l10n.reply,
                            onPressed: busy ? null : () => _write(m),
                          ),
                        ),
                      ],
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
                if (canReply && !desk)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      pageMargin,
                      Space.s,
                      pageMargin,
                      MediaQuery.paddingOf(context).bottom + Space.s,
                    ),
                    // A pill under the text beside the list; the full width on
                    // a phone.
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox(
                        width: widget.onGone != null ? null : double.infinity,
                        child: FilledButton(
                          onPressed: busy ? null : () => _write(m),
                          child: Text(
                            _folder == MailFolder.drafts
                                ? l10n.editDraft
                                : l10n.reply,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
