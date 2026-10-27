import 'package:clock/clock.dart' as clk;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../l10n/l10n.dart';
import '../core/desk_list.dart';
import '../core/desktop_mode.dart';
import '../core/compose_screen.dart';
import '../core/floating_dock.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'course_detail_screen.dart';
import 'module_screen.dart';

/// A forum's discussions (design/round-11 course-modules-screens): pinned
/// ones marked, each with a two-line excerpt, author, date and replies.
class ForumBody extends StatefulWidget {
  const ForumBody({
    super.key,
    required this.courseId,
    required this.forumId,
    required this.title,
  });

  final int courseId, forumId;
  final String title;

  @override
  State<ForumBody> createState() => _ForumBodyState();
}

class _ForumBodyState extends State<ForumBody> {
  /// Bumped after starting a discussion, so the list loads it.
  var _version = 0;
  late final _canStart = context.read<EcourseRepository>().canStartDiscussion(
    widget.forumId,
  );

  Future<void> _start() async {
    final l10n = context.l10n;
    final repo = context.read<EcourseRepository>();
    final sent = await compose(
      context,
      title: l10n.newDiscussion,
      hint: l10n.messageBody,
      withSubject: true,
      send: (subject, text) =>
          repo.startDiscussion(widget.forumId, subject, text),
    );
    if (sent && mounted) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    final desk = desktopUi(context);
    // Only where eCourse2 lets this student post; a news forum does not.
    final start = FutureBuilder(
      future: _canStart,
      builder: (context, can) => can.data != true
          ? const SizedBox.shrink()
          : desk
          ? DeskButton(
              icon: Icons.add,
              label: context.l10n.newDiscussion,
              primary: true,
              onPressed: _start,
            )
          : FloatingAction(
              onPressed: _start,
              icon: Icons.add,
              label: context.l10n.newDiscussion,
            ),
    );
    final list = Loader<List<Discussion>>.watch(
      key: ValueKey(_version),
      watch: () => repo.watch((repo) => repo.discussions(widget.forumId)),
      builder: (context, discussions) => discussions.isEmpty
          ? EmptyState(context.l10n.noDiscussions)
          : DiscussionList(
              courseId: widget.courseId,
              kind: context.l10n.msgForum,
              title: widget.title,
              discussions: discussions,
              action: desk ? start : null,
            ),
    );
    if (desk) return list;
    return Stack(
      children: [
        list,
        Positioned(
          right: pageMargin,
          bottom: MediaQuery.paddingOf(context).bottom + 16,
          child: start,
        ),
      ],
    );
  }
}

class DiscussionList extends StatelessWidget {
  const DiscussionList({
    super.key,
    required this.courseId,
    required this.kind,
    required this.title,
    required this.discussions,
    this.action,
  });

  final int courseId;

  /// The page's kind and name, heading the list on a desktop.
  final String kind, title;
  final List<Discussion> discussions;

  /// On a desktop, under the heading, such as 新增討論.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: scheme.onSurfaceVariant,
    );
    void open(Discussion d) => context.push(
      '/courses/$courseId/discussions/${d.id}',
      extra: d.subject,
    );
    if (desktopUi(context)) {
      // The rows pad themselves; the heading lines up with their text.
      return ListView(
        padding: EdgeInsets.fromLTRB(16, scrollPadding(context).top, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: CoursePageHead(
              courseId: courseId,
              kind: kind,
              title: title,
              meta: [(context.l10n.postCount(discussions.length), null)],
            ),
          ),
          if (action case final action?)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
              child: Align(alignment: Alignment.centerLeft, child: action),
            ),
          for (final d in discussions)
            DeskRow(
              leading: SizedBox(
                width: 16,
                child: d.pinned
                    ? Icon(
                        Icons.push_pin_outlined,
                        size: 15,
                        color: context.tones.sun.strong,
                      )
                    : null,
              ),
              title: d.subject,
              excerpt: d.body.isEmpty ? null : d.body,
              subtitle: '${d.author}・${dateLabel(d.time)}',
              trailing: d.replies == 0
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text('${d.replies}', style: muted),
                      ],
                    ),
              onTap: () => open(d),
            ),
        ],
      );
    }
    return ListView(
      padding: scrollPadding(context),
      children: [
        Card(
          color: scheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, d) in discussions.indexed) ...[
                if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
                InkWell(
                  onTap: () => open(d),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.l,
                      Space.m,
                      Space.l,
                      Space.m,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              if (d.pinned)
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      right: Space.xs,
                                    ),
                                    child: Icon(
                                      Icons.push_pin,
                                      size: 16,
                                      color: context.tones.sun.strong,
                                    ),
                                  ),
                                ),
                              TextSpan(text: d.subject),
                            ],
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1.35,
                          ),
                        ),
                        if (d.body.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: Space.xs),
                            child: Text(
                              d.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${d.author}・${dateLabel(d.time)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: muted,
                              ),
                            ),
                            Icon(
                              Icons.forum_outlined,
                              size: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text('${d.replies}', style: muted),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// `10/15`, or with the year when it is not this year.
String dateLabel(DateTime t) => t.year == clk.clock.now().year
    ? '${t.month}/${t.day}'
    : '${t.year}/${t.month}/${t.day}';

/// One discussion: the opening post as the hero, replies indented below,
/// and a bar to reply (design/round-11 reply-comment-mail).
class DiscussionScreen extends StatefulWidget {
  const DiscussionScreen({super.key, required this.discussionId, this.title});

  final int discussionId;

  /// The discussion's subject when the opener knows it.
  final String? title;

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  /// Bumped after a reply, so the posts load again with it.
  var _version = 0;

  Future<void> _reply(ForumPost to) async {
    final l10n = context.l10n;
    final repo = context.read<EcourseRepository>();
    final subject = to.subject.startsWith('Re: ')
        ? to.subject
        : 'Re: ${to.subject}';
    final sent = await compose(
      context,
      title: l10n.reply,
      hint: l10n.messageBody,
      replyingTo: to.author,
      send: (_, text) => repo.replyToPost(to.id, subject, text),
    );
    if (sent && mounted) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    final desk = desktopUi(context);
    // Opened from a course rather than a notification: its path leads back.
    final courseId = int.tryParse(
      GoRouterState.of(context).pathParameters['id'] ?? '',
    );
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(
        context,
        widget.title ?? '',
        titleChild: desk && courseId != null
            ? CourseCrumbs(courseId: courseId, trail: [widget.title ?? ''])
            : null,
      ),
      body: Loader<List<ForumPost>>.watch(
        key: ValueKey(_version),
        watch: () =>
            repo.watch((repo) => repo.discussionPosts(widget.discussionId)),
        builder: (context, posts) {
          if (posts.isEmpty) return EmptyState(context.l10n.noDiscussions);
          final [first, ...replies] = posts;
          if (desk) return _desk(context, first, replies);
          return Stack(
            children: [
              Positioned.fill(
                child: ListView(
                  // Ends above the reply dock floating over it.
                  padding: scrollPadding(context).copyWith(
                    bottom:
                        scrollPadding(context).bottom + FloatingDock.clearance,
                  ),
                  children: [
                    _Post(
                      post: first,
                      lead: true,
                      onReply: () => _reply(first),
                    ),
                    if (replies.isNotEmpty) ...[
                      SectionLabel(context.l10n.replyCount(replies.length)),
                      for (final p in replies)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: Space.xl,
                            bottom: Space.s,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(left: Space.m),
                              child: _Post(
                                post: p,
                                lead: false,
                                onReply: () => _reply(p),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ComposeBar(
                  hint: context.l10n.replyToThread,
                  onTap: () => _reply(first),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

extension on _DiscussionScreenState {
  /// design/round-25: the opening post and each reply in a box, replies
  /// indented, the field to reply below the page.
  Widget _desk(BuildContext context, ForumPost first, List<ForumPost> replies) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: scrollPadding(context),
            children: [
              _Post(post: first, lead: true, onReply: () => _reply(first)),
              if (replies.isNotEmpty) ...[
                SectionLabel(context.l10n.replyCount(replies.length)),
                for (final p in replies)
                  Padding(
                    padding: const EdgeInsets.only(left: 28, top: Space.s),
                    child: _Post(
                      post: p,
                      lead: false,
                      onReply: () => _reply(p),
                    ),
                  ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: ComposeBar(
            hint: context.l10n.replyToThread,
            onTap: () => _reply(first),
            inline: true,
          ),
        ),
      ],
    );
  }
}

class _Post extends StatelessWidget {
  const _Post({required this.post, required this.lead, required this.onReply});

  final ForumPost post;
  final VoidCallback onReply;

  /// The opening post: colored, with its subject.
  final bool lead;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = context.tones.lilac;
    if (desktopUi(context)) return _desk(context, scheme, tone);
    final ink = lead ? tone.ink : scheme.onSurface;
    return Card(
      color: lead ? tone.fill : scheme.surfaceContainerLow,
      margin: lead ? null : EdgeInsets.zero,
      child: Padding(
        padding: cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: lead ? tone.strong : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(Corners.small),
                  ),
                  child: Text(
                    post.author.characters.firstOrNull ?? '',
                    style: TextStyle(
                      color: lead ? tone.fill : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author,
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        dateTimeLabel(context, post.time),
                        style: TextStyle(
                          color: ink.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (lead && post.subject.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: Space.m),
                child: Text(
                  post.subject,
                  style: TextStyle(
                    color: ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
              ),
            if (post.body.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: Space.s),
                child: SelectableText(
                  post.body,
                  style: TextStyle(color: ink, fontSize: 14, height: 1.6),
                ),
              ),
            if (post.attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: Space.m),
                child: FileList(
                  files: post.attachments,
                  detail: (f) => fileSize(f.size),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: Space.s),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: ink,
                  backgroundColor: ink.withValues(alpha: 0.1),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: onReply,
                child: Text(context.l10n.reply),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// design/round-25: a bordered box; the opening post carries its subject,
  /// a reply its author on one line with the text indented under it.
  Widget _desk(BuildContext context, ColorScheme scheme, Tone tone) {
    final muted = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    const prose = TextStyle(
      fontSize: 13,
      height: 1.75,
      fontWeight: FontWeight.w700,
    );
    final avatar = CircleAvatar(
      radius: 12,
      backgroundColor: lead ? tone.fill : scheme.surfaceContainerHigh,
      foregroundColor: lead ? tone.ink : scheme.onSurfaceVariant,
      child: Text(
        post.author.characters.firstOrNull ?? '',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
    final name = Text(
      post.author,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
    );
    final time = Text(dateTimeLabel(context, post.time), style: muted);
    final reply = DeskButton(
      icon: Icons.reply,
      label: context.l10n.reply,
      onPressed: onReply,
    );
    return Container(
      margin: lead ? const EdgeInsets.only(top: Space.m) : null,
      padding: lead
          ? const EdgeInsets.symmetric(horizontal: 18, vertical: Space.l)
          : const EdgeInsets.symmetric(horizontal: Space.l, vertical: 11),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 10,
            children: [
              avatar,
              if (lead)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [name, time],
                )
              else ...[
                name,
                time,
              ],
              const Spacer(),
              reply,
            ],
          ),
          if (lead && post.subject.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Space.m),
              child: Text(
                post.subject,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
          if (post.body.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: Space.xs, left: lead ? 0 : 34),
              child: SelectableText(post.body, style: prose),
            ),
          if (post.attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Space.s),
              child: FileList(
                files: post.attachments,
                detail: (f) => fileSize(f.size),
              ),
            ),
        ],
      ),
    );
  }
}
