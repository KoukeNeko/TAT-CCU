import 'package:clock/clock.dart' as clk;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../core/desk_list.dart';
import '../core/desktop_mode.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../courses/course_detail_screen.dart';
import '../courses/module_screen.dart';
import '../../l10n/l10n.dart';

/// Assignments, quizzes and other dated activities in the next two weeks.
class DueScreen extends StatelessWidget {
  const DueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EcourseRepository>();
    if (desktopUi(context) && listBeside(context)) {
      return Loader<List<DueItem>>.watch(
        bar: _deskBar,
        watch: () => repo.watch((repo) => repo.dueSoon()),
        builder: (context, items) => _DeskDue(items: items),
      );
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, context.l10n.toDo),
      body: Loader<List<DueItem>>.watch(
        watch: () => repo.watch((repo) => repo.dueSoon()),
        builder: (context, items) {
          if (items.isEmpty) return EmptyState(context.l10n.nothingDueSoon);
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

AppBar _deskBar(BuildContext context) => deskCrumbBar(
  context,
  parent: context.l10n.navToday,
  path: '/today',
  title: context.l10n.toDo,
);

/// design/round-25 待辦: every item in a list, the picked one's page beside
/// it.
class _DeskDue extends StatefulWidget {
  const _DeskDue({required this.items});

  final List<DueItem> items;

  @override
  State<_DeskDue> createState() => _DeskDueState();
}

class _DeskDueState extends State<_DeskDue> {
  var _picked = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final now = clk.clock.now();
    final items = widget.items;
    final picked = items.elementAtOrNull(_picked);
    final cmid = int.tryParse(
      Uri.tryParse(picked?.url ?? '')?.queryParameters['id'] ?? '',
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: listWidthOf(context),
          child: LeadingPane(
            child: PaneSize(
              child: Scaffold(
                appBar: _deskBar(context),
                body: items.isEmpty
                    ? EmptyState(l10n.nothingDueSoon)
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          DeskGroup(
                            l10n.within14Days,
                            trailing: Text(l10n.itemCount(items.length)),
                          ),
                          for (final (i, item) in items.indexed)
                            DeskRow(
                              leading: SizedBox(
                                width: 46,
                                child: Text(
                                  timeLeft(l10n, item.due),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    // Within two days, as on a phone.
                                    color: item.due.difference(now).inHours < 48
                                        ? tones.peach.strong
                                        : tones.sun.strong,
                                  ),
                                ),
                              ),
                              title: item.name,
                              subtitle:
                                  '${context.courseNameOf(item.course)}・'
                                  '${dateTimeLabel(context, item.due)}',
                              trailing: DeskStripe(
                                tones.forCourse(item.courseId).strong,
                              ),
                              selected: i == _picked,
                              onTap: () => setState(() => _picked = i),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        Padding(
          // Under the bars, so the two read as one toolbar.
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + desktopBarHeight,
          ),
          child: VerticalDivider(width: 1, color: scheme.outlineVariant),
        ),
        Expanded(
          child: PaneSize(
            child:
                picked != null &&
                    cmid != null &&
                    moduleTypesWithPage.contains(picked.module)
                ? ModuleScreen(
                    key: ValueKey(cmid),
                    courseId: picked.courseId,
                    cmid: cmid,
                    title: picked.name,
                  )
                : const EmptyPane(),
          ),
        ),
      ],
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
    final left = item.due.difference(clk.clock.now());
    final urgent = left.inHours < 48;
    final tone = urgent ? tones.peach : tones.forCourse(item.courseId);
    final value = left.inHours < 24 ? '${left.inHours}' : '${left.inDays}';
    final unit = left.inHours < 24
        ? context.l10n.unitHours
        : context.l10n.unitDays;
    return ToneBlock(
      tone: tone,
      padding: cardPadding,
      onTap: item.url == null ? null : () => openDueItem(context, item),
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
                  context.courseNameOf(item.course),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  dateTimeLabel(context, item.due),
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

/// Opens the in-app module page when there is one; the event URL is the
/// module's `view.php?id=<cmid>`. Anything else opens eCourse2.
void openDueItem(BuildContext context, DueItem item) {
  final cmid = int.tryParse(
    Uri.tryParse(item.url ?? '')?.queryParameters['id'] ?? '',
  );
  if (cmid != null && moduleTypesWithPage.contains(item.module)) {
    context.push('/courses/${item.courseId}/modules/$cmid');
  } else if (item.url != null) {
    openExternal(item.url!);
  }
}
