import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/ecourse_auth_repository.dart';
import '../../data/repositories/campus_cache.dart';
import '../../data/repositories/ecourse_repository.dart';
import '../../data/repositories/more_tiles_prefs.dart';
import '../core/desk_list.dart';
import '../core/desktop_mode.dart';
import '../core/auto_refresh.dart';
import '../core/glass_dialog.dart';
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
  const MoreScreen({super.key, this.open});

  /// The page open beside this list in a wide window; its row is lit.
  final String? open;

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> with AutoRefresh {
  /// Each course's grade, saved answer first; the tile only shows a count
  /// and skips it on failure.
  Map<int, String>? _grades;
  StreamSubscription<Map<int, String>>? _gradesSub;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  void _loadGrades() {
    _gradesSub?.cancel();
    _gradesSub = context
        .read<EcourseRepository>()
        .watch((repo) => repo.gradeOverview())
        .listen((g) => setState(() => _grades = g), onError: (_) {});
  }

  // The tiles: grades from eCourse2, the library and leave from what
  // their pages last saved.
  @override
  void refresh() => setState(() {
    _loadGrades();
    _library = CampusCache.read(LibraryScreen.cacheKey);
    _leave = CampusCache.read(LeaveScreen.cacheKey);
  });

  @override
  void dispose() {
    _gradesSub?.cancel();
    super.dispose();
  }

  // shortcut: the tiles read each page's last saved data again only when
  // the More page refreshes ([AutoRefresh]); listen to the cache if a tile
  // lagging behind its page shows.
  var _library = CampusCache.read(LibraryScreen.cacheKey);
  var _leave = CampusCache.read(LeaveScreen.cacheKey);
  final _slots = List.generate(4, (_) => GlobalKey());
  var _query = '';

  /// On a flip phone's outer display the search field shows once its
  /// button in the title is pressed.
  var _searchOpen = false;

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
              onOpen: _open,
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
                  height: StatusTile.heightOf(context),
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

  /// Beside the list (desktop) a page replaces the one open there;
  /// otherwise it is pushed, so back returns here.
  void _open(String path) =>
      widget.open != null ? context.go(path) : context.push(path);

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final prefs = context.watch<MoreTilesPrefs>();
    final pages = _pages(context);
    final scheme = Theme.of(context).colorScheme;
    final auth = context.watch<EcourseAuthRepository>();
    final signedIn = auth.isSignedIn;
    final searching = _query.isNotEmpty;
    final cover = coverScreen(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      // Beside a page on a desktop, that page's bar names the way here.
      appBar: desktopUi(context) && widget.open != null
          ? topBar('')
          : topBar(
              context.l10n.navMore,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: Space.l),
                  child: cover
                      ? IconButton(
                          tooltip: context.l10n.searchSystems,
                          style: IconButton.styleFrom(
                            backgroundColor: scheme.surfaceContainer,
                          ),
                          icon: const Icon(Icons.search),
                          onPressed: () => setState(() {
                            _searchOpen = !_searchOpen;
                            if (!_searchOpen) _query = '';
                          }),
                        )
                      : IconButton(
                          tooltip: context.l10n.pageStages,
                          style: IconButton.styleFrom(
                            backgroundColor: scheme.surfaceContainer,
                          ),
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => _showStages(context),
                        ),
                ),
              ],
            ),
      body: Builder(
        // Reads insets from inside this Scaffold, below the glass app bar.
        builder: (context) => ListView(
          padding: scrollPadding(context),
          // All of it built beside a desktop page, so the open page's row,
          // however low, can scroll itself into view.
          scrollCacheExtent: desktopUi(context)
              ? const ScrollCacheExtent.pixels(double.infinity)
              : null,
          children: [
            // A flip phone's outer display searches from the title instead.
            if (!cover || _searchOpen)
              TextField(
                autofocus: cover,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: context.l10n.searchSystems,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            if (!searching) ...[
              if (!cover || _searchOpen) const SizedBox(height: rowGap),
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
            ...campusSystemSections(context, _query, open: widget.open),
            if (!searching) ...[
              SectionLabel(context.l10n.aboutApp),
              Card(
                // Rows straight under the heading on a desktop.
                color: desktopUi(context)
                    ? Colors.transparent
                    : scheme.surfaceContainerLow,
                shape: desktopUi(context)
                    ? const RoundedRectangleBorder()
                    : null,
                margin: desktopUi(context) ? EdgeInsets.zero : null,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    MenuRow(
                      tone: t.peach,
                      icon: Icons.handyman_outlined,
                      title: context.l10n.tools,
                      selected: widget.open == '/more/tools',
                      onTap: () => _open('/more/tools'),
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
                      selected: widget.open == '/more/account',
                      onTap: () => _open('/more/account'),
                    ),
                    MenuRow(
                      tone: t.mint,
                      icon: Icons.tune,
                      title: context.l10n.settings,
                      selected: widget.open == '/more/settings',
                      onTap: () => _open('/more/settings'),
                    ),
                    MenuRow(
                      tone: t.sun,
                      icon: Icons.palette_outlined,
                      title: context.l10n.designLanguage,
                      selected: widget.open == '/more/design',
                      onTap: () => _open('/more/design'),
                    ),
                    MenuRow(
                      tone: t.peach,
                      icon: Icons.info_outline,
                      title: context.l10n.about,
                      selected: widget.open == '/more/about',
                      onTap: () => _open('/more/about'),
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
    required this.onOpen,
    required this.grades,
    required this.library,
    required this.leave,
  });

  final _Page page;
  final ValueChanged<String> onOpen;
  final Map<int, String>? grades;
  final Future<CachedPage?> library, leave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final status = switch (page.path) {
      '/more/grades' => _face(
        context,
        page.tone,
        grades == null ? null : l10n.courseCount(grades!.length),
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
    onTap: () => onOpen(page.path),
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
    this.selected = false,
  });

  final bool selected;
  final Tone tone;
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (desktopUi(context)) {
      return DeskRow(
        leading: Icon(icon, size: 16, color: tone.strong),
        title: title,
        selected: selected,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?trailing,
            Icon(Icons.chevron_right, size: 16, color: scheme.onSurfaceVariant),
          ],
        ),
        onTap: onTap,
      );
    }
    return ListTile(
      tileColor: selected ? scheme.surfaceContainerHigh : null,
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

/// What ALPHA and BETA beside a system mean, on frosted glass.
void _showStages(BuildContext context) {
  final l10n = context.l10n;
  final tones = context.tones;
  showGlassDialog<void>(
    context: context,
    builder: (context) => GlassDialog(
      title: l10n.pageStages,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.stagesHelp),
          const SizedBox(height: Space.l),
          for (final (stage, tone, title, detail) in [
            ('ALPHA', tones.peach, l10n.stageAlpha, l10n.stageAlphaDetail),
            ('BETA', tones.lilac, l10n.stageBeta, l10n.stageBetaDetail),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: Space.m),
              child: Row(
                children: [
                  SizedBox(
                    width: 76,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: StatusPill(tone: tone, label: stage),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(detail, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
        FilledButton(
          onPressed: () => _reportIssue(context),
          child: Text(l10n.reportIssue),
        ),
      ],
    ),
  );
}

/// A new GitHub issue with the version and platform filled in.
Future<void> _reportIssue(BuildContext context) async {
  final l10n = context.l10n;
  final info = await PackageInfo.fromPlatform();
  await launchUrl(
    Uri.https('github.com', '/KoukeNeko/TAT-CCU/issues/new', {
      'body': l10n.issueTemplate(
        '${info.version} (${info.buildNumber})',
        defaultTargetPlatform.name,
      ),
    }),
    mode: LaunchMode.externalApplication,
  );
}
