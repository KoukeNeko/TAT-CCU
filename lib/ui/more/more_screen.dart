import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_auth_repository.dart';
import '../../data/repositories/campus_cache.dart';
import '../../data/repositories/ecourse_repository.dart';
import '../../data/repositories/more_tiles_prefs.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'leave_screen.dart';
import 'library_screen.dart';
import '../core/campus_systems.dart';
import '../../l10n/l10n.dart';

/// A native page the More page can show as a status tile or a row.
typedef _Page = ({String path, IconData icon, Tone tone, String title});

/// Design round-11 more-a-full: a search, four status tiles the student
/// picks (long-press to replace, drag to reorder), every campus system by
/// office with the in-app pages first, then the app.
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  /// Fetched once; the row only shows a count and skips it on failure.
  late final _grades = context.read<EcourseRepository>().gradeOverview();
  // shortcut: the tiles read each page's last saved data once, so they lag
  // until the More page is rebuilt; listen to the cache if that shows.
  final _library = CampusCache.read(LibraryScreen.cacheKey);
  final _leave = CampusCache.read(LeaveScreen.cacheKey);
  final _slots = List.generate(4, (_) => GlobalKey());
  var _query = '';

  Map<String, _Page> _pages(BuildContext context) {
    final t = context.tones;
    final l10n = context.l10n;
    return {
      for (final p in <_Page>[
        (
          path: '/more/space',
          icon: Icons.qr_code_2,
          tone: t.lilac,
          title: l10n.studySpace,
        ),
        (
          path: '/more/library',
          icon: Icons.menu_book_outlined,
          tone: t.mint,
          title: l10n.library,
        ),
        (
          path: '/more/grades',
          icon: Icons.grading_outlined,
          tone: t.sun,
          title: l10n.grades,
        ),
        (
          path: '/more/leave',
          icon: Icons.event_busy_outlined,
          tone: t.peach,
          title: l10n.leave,
        ),
        (
          path: '/more/iccu',
          icon: Icons.edit_calendar_outlined,
          tone: t.sun,
          title: l10n.courseSelection,
        ),
        (
          path: '/more/academic',
          icon: Icons.badge_outlined,
          tone: t.lilac,
          title: l10n.academicRecord,
        ),
        (
          path: '/more/library/search',
          icon: Icons.travel_explore,
          tone: t.mint,
          title: l10n.libraryDiscovery,
        ),
      ])
        p.path: p,
    };
  }

  /// The four tiles: saved routes that no longer exist (a renamed page) are
  /// skipped and the rest filled up from the other pages.
  List<String> _tilesOf(MoreTilesPrefs prefs, Map<String, _Page> pages) {
    final kept = {
      for (final t in prefs.tiles)
        if (pages.containsKey(t)) t,
    };
    return [
      ...kept,
      ...pages.keys.where((p) => !kept.contains(p)),
    ].take(4).toList();
  }

  Future<void> _replace(
    MoreTilesPrefs prefs,
    Map<String, _Page> pages,
    int i,
  ) async {
    final tiles = _tilesOf(prefs, pages);
    final box = _slots[i].currentContext!.findRenderObject()! as RenderBox;
    final path = await showGlassMenu<String>(
      context,
      anchor: box.localToGlobal(Offset.zero) & box.size,
      title: context.l10n.replaceWith,
      items: [
        for (final p in pages.values)
          if (!tiles.contains(p.path))
            (
              value: p.path,
              tone: p.tone,
              icon: p.icon,
              title: p.title,
              detail: null,
            ),
      ],
    );
    if (path == null) return;
    prefs.setTiles(tiles..[i] = path);
  }

  void _swap(MoreTilesPrefs prefs, Map<String, _Page> pages, int from, int to) {
    final tiles = _tilesOf(prefs, pages);
    final moved = tiles[from];
    tiles[from] = tiles[to];
    tiles[to] = moved;
    HapticFeedback.selectionClick();
    prefs.setTiles(tiles);
  }

  Widget _slot(MoreTilesPrefs prefs, Map<String, _Page> pages, int i) {
    final page = pages[_tilesOf(prefs, pages)[i]]!;
    return Expanded(
      child: KeyedSubtree(
        key: _slots[i],
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tile = _StatusTile(
              page: page,
              grades: _grades,
              library: _library,
              leave: _leave,
            );
            return DragTarget<int>(
              // Dropped where it started: a long press without a drag.
              onAcceptWithDetails: (d) => d.data == i
                  ? _replace(prefs, pages, i)
                  : _swap(prefs, pages, d.data, i),
              builder: (context, hovering, _) => LongPressDraggable<int>(
                data: i,
                feedback: SizedBox(
                  width: constraints.maxWidth,
                  height: StatusTile.height,
                  child: Transform.scale(
                    scale: 1.04,
                    child: PhysicalShape(
                      clipper: ShapeBorderClipper(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Corners.card),
                        ),
                      ),
                      color: Colors.transparent,
                      elevation: 12,
                      child: tile,
                    ),
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.3, child: tile),
                child: AnimatedScale(
                  scale: hovering.any((from) => from != i) ? 0.94 : 1,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutQuart,
                  child: tile,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final prefs = context.watch<MoreTilesPrefs>();
    final pages = _pages(context);
    final scheme = Theme.of(context).colorScheme;
    final auth = context.watch<EcourseAuthRepository>();
    final signedIn = auth.isSignedIn;
    final searching = _query.isNotEmpty;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: topBar(context.l10n.navMore),
      body: Builder(
        // Reads insets from inside this Scaffold, below the glass app bar.
        builder: (context) => ListView(
          padding: scrollPadding(context),
          children: [
            TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: context.l10n.searchSystems,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            if (!searching) ...[
              const SizedBox(height: rowGap),
              for (final row in [0, 2]) ...[
                if (row > 0) const SizedBox(height: rowGap),
                Row(
                  children: [
                    _slot(prefs, pages, row),
                    const SizedBox(width: rowGap),
                    _slot(prefs, pages, row + 1),
                  ],
                ),
              ],
            ],
            ...campusSystemSections(context, _query),
            if (!searching) ...[
              SectionLabel(context.l10n.aboutApp),
              Card(
                color: scheme.surfaceContainerLow,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    MenuRow(
                      tone: t.peach,
                      icon: Icons.handyman_outlined,
                      title: context.l10n.tools,
                      onTap: () => context.push('/more/tools'),
                    ),
                    MenuRow(
                      tone: t.lilac,
                      icon: Icons.person_outline,
                      title: context.l10n.account,
                      trailing: StatusPill(
                        tone: auth.isDemo
                            ? t.lilac
                            : signedIn
                            ? t.mint
                            : t.peach,
                        label: auth.isDemo
                            ? context.l10n.demoMode
                            : signedIn
                            ? context.l10n.ecourseSignedIn
                            : context.l10n.ecourseSignedOut,
                      ),
                      onTap: () => context.push('/more/account'),
                    ),
                    MenuRow(
                      tone: t.mint,
                      icon: Icons.tune,
                      title: context.l10n.settings,
                      onTap: () => context.push('/more/settings'),
                    ),
                    MenuRow(
                      tone: t.sun,
                      icon: Icons.palette_outlined,
                      title: context.l10n.designLanguage,
                      onTap: () => context.push('/more/design'),
                    ),
                    MenuRow(
                      tone: t.peach,
                      icon: Icons.info_outline,
                      title: context.l10n.about,
                      onTap: () => context.push('/more/about'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A [StatusTile] with the page's state read from its saved data.
class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.page,
    required this.grades,
    required this.library,
    required this.leave,
  });

  final _Page page;
  final Future<Map<int, String>> grades;
  final Future<CachedPage?> library, leave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final status = switch (page.path) {
      '/more/grades' => FutureBuilder(
        future: grades,
        builder: (context, snap) => _face(
          context,
          page.tone,
          snap.hasData ? l10n.courseCount(snap.data!.length) : null,
        ),
      ),
      '/more/library' => FutureBuilder(
        future: library,
        builder: (context, snap) {
          final loan = loanStatus(l10n, snap.data);
          return _face(
            context,
            loan?.overdue == true ? tones.peach : page.tone,
            loan?.text,
          );
        },
      ),
      '/more/leave' => FutureBuilder(
        future: leave,
        builder: (context, snap) => _face(
          context,
          page.tone,
          snap.data != null && pendingLeaveCount(snap.data!.json) > 0
              ? l10n.leavePending
              : null,
        ),
      ),
      _ => _face(context, page.tone, null),
    };
    return status;
  }

  Widget _face(BuildContext context, Tone tone, String? status) => StatusTile(
    tone: tone,
    icon: page.icon,
    title: page.title,
    status: status,
    onTap: () => context.push(page.path),
  );
}

/// A More-style row: a toned icon square, a title and a chevron.
class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.tone,
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final Tone tone;
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: tone.fill,
          borderRadius: BorderRadius.circular(Corners.small),
        ),
        child: Icon(icon, size: 20, color: tone.ink),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?trailing,
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
      onTap: onTap,
    );
  }
}
