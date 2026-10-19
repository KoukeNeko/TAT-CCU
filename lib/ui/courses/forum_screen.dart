import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../l10n/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'module_screen.dart';

/// A forum's discussions (design/round-11 course-modules-screens): pinned
/// ones marked, each with a two-line excerpt, author, date and replies.
class ForumBody extends StatelessWidget {
  const ForumBody({super.key, required this.courseId, required this.forumId});

  final int courseId, forumId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Loader<List<Discussion>>.watch(
      watch: () => repo.watch((repo) => repo.discussions(forumId)),
      builder: (context, discussions) => discussions.isEmpty
          ? EmptyState(context.l10n.noDiscussions)
          : DiscussionList(courseId: courseId, discussions: discussions),
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
                  onTap: () => context.push(
                    '/courses/$courseId/discussions/${d.id}',
                    extra: d.subject,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
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
                                    padding: const EdgeInsets.only(right: 4),
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
                            padding: const EdgeInsets.only(top: 4),
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
String dateLabel(DateTime t) => t.year == DateTime.now().year
    ? '${t.month}/${t.day}'
    : '${t.year}/${t.month}/${t.day}';

/// One discussion: the opening post as the hero, replies indented below.
class DiscussionScreen extends StatelessWidget {
  const DiscussionScreen({super.key, required this.discussionId, this.title});

  final int discussionId;

  /// The discussion's subject when the opener knows it.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, title ?? ''),
      body: Loader<List<ForumPost>>.watch(
        watch: () => repo.watch((repo) => repo.discussionPosts(discussionId)),
        builder: (context, posts) {
          if (posts.isEmpty) return EmptyState(context.l10n.noDiscussions);
          final [first, ...replies] = posts;
          return ListView(
            padding: scrollPadding(context),
            children: [
              _Post(post: first, lead: true),
              if (replies.isNotEmpty) ...[
                SectionLabel(context.l10n.replyCount(replies.length)),
                for (final p in replies)
                  Padding(
                    padding: const EdgeInsets.only(left: 18, bottom: 8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: _Post(post: p, lead: false),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Post extends StatelessWidget {
  const _Post({required this.post, required this.lead});

  final ForumPost post;

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
        padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.only(top: 12),
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
                padding: const EdgeInsets.only(top: 8),
                child: SelectableText(
                  post.body,
                  style: TextStyle(color: ink, fontSize: 14, height: 1.6),
                ),
              ),
            if (post.attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FileList(
                  files: post.attachments,
                  detail: (f) => fileSize(f.size),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
