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
import 'module_screen.dart';

/// A forum's discussions (design/round-11 course-modules-screens): pinned
/// ones marked, each with a two-line excerpt, author, date and replies.
class ForumBody extends StatefulWidget {
  const ForumBody({super.key, required this.courseId, required this.forumId});

  final int courseId, forumId;

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
    return Stack(
      children: [
        Loader<List<Discussion>>.watch(
          key: ValueKey(_version),
          watch: () => repo.watch((repo) => repo.discussions(widget.forumId)),
          builder: (context, discussions) => discussions.isEmpty
              ? EmptyState(context.l10n.noDiscussions)
              : DiscussionList(
                  courseId: widget.courseId,
                  discussions: discussions,
                ),
        ),
        // Only where eCourse2 lets this student post; a news forum does not.
        Positioned(
          right: pageMargin,
          bottom: MediaQuery.paddingOf(context).bottom + 16,
          child: FutureBuilder(
            future: _canStart,
            builder: (context, can) => can.data != true
                ? const SizedBox.shrink()
                : FloatingAction(
                    onPressed: _start,
                    icon: Icons.add,
                    label: context.l10n.newDiscussion,
                  ),
          ),
        ),
      ],
    );
  }
}

class DiscussionList extends StatelessWidget {
  const DiscussionList({
    super.key,
    required this.courseId,
    required this.discussions,
  });

  final int courseId;
  final List<Discussion> discussions;

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
      return ListView(
        padding: EdgeInsets.fromLTRB(16, scrollPadding(context).top, 16, 32),
        children: [
          for (final d in discussions)
            DeskRow(
              leading: Icon(
                d.pinned ? Icons.push_pin : Icons.forum_outlined,
                size: 16,
                color: d.pinned
                    ? context.tones.sun.strong
                    : scheme.onSurfaceVariant,
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, widget.title ?? ''),
      body: Loader<List<ForumPost>>.watch(
        key: ValueKey(_version),
        watch: () =>
            repo.watch((repo) => repo.discussionPosts(widget.discussionId)),
        builder: (context, posts) {
          if (posts.isEmpty) return EmptyState(context.l10n.noDiscussions);
          final [first, ...replies] = posts;
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
}
