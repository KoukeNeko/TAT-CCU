import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../domain/models/course.dart';
import 'auto_refresh.dart';
import 'theme.dart';
import 'widgets.dart';
import '../../l10n/l10n.dart';

typedef _Tab = (IconData icon, String label, Tone tone, ShapeBorder shape);

const _barHeight = 72.0;

/// The bar stood upright on the right (iPhone Duo, design/round-12
/// duo-variants B): its width, inset and icon slots.
const _uprightWidth = 62.0;
const _uprightInset = 7.0;
const _uprightSlot = 48.0;
const _uprightGap = 4.0;

const _sidebarWidth = 232.0;

/// On macOS the rail is as wide as the window's traffic lights are far from
/// its edge doubled, so its icons line up under the middle (yellow) one.
final _railWidth = Platform.isMacOS ? 98.0 : 72.0;

/// Selected label style; the capsule is sized from it.
const _labelStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w900);

/// Left inset, icon, gap and right inset around the selected label; the
/// icon sits as far from the capsule edge as from its top: (52 - 38) / 2.
const _capsuleChrome = 7.0 + 38 + 8 + 16;

/// Narrowest an unselected slot gets, so long labels never squeeze icons.
const _minSlot = 44.0;

/// The nav bar's motion, shared with the bars that behave like it (the
/// sign-in's language bar). Tuned toward SwiftUI's default spring:
/// unhurried, settles without a visible bounce.
const barMove = Duration(milliseconds: 480);
const barSettle = Curves.easeOutQuart;

/// Finger travel before a press turns into a drag, so a tap never makes the
/// capsule jump around.
const barDragSlop = 12.0;

/// Floating nav bar, variant C3 "色塊膠囊" (design/round-04): only the
/// selected tab has color; it stretches into a capsule of its own function
/// color with its icon set inside its silhouette.
///
/// Like the iOS tab bar, a finger can press anywhere on the bar and slide
/// across it: the capsule follows the finger, each new tab ticks, and lifting
/// the finger commits the tab under it.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.shell, required this.location});

  final StatefulNavigationShell shell;

  /// Where the app is; the sidebar lights the course being shown.
  final String location;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Where the finger went down along the bar; null when nothing is
  /// touching.
  double? _down;

  /// Tab the capsule follows while dragging; null for a plain press.
  int? _hover;

  int get _shown => _hover ?? widget.shell.currentIndex;

  /// The full sidebar is open over the page from the rail.
  var _expanded = false;

  /// Width of each tab's capsule when selected, from its label in the
  /// current language and text size; set on every layout.
  List<double> _capsules = const [];

  /// Slot widths with [selected] widened to its capsule.
  List<double> _slots(double width, int selected) {
    final n = _capsules.length;
    final active = _capsules[selected];
    final other = (width - active) / (n - 1);
    return [for (var i = 0; i < n; i++) i == selected ? active : other];
  }

  /// Tab slot under [x]; slots are laid out for the tab currently shown, so
  /// the widened capsule stays under the finger and does not flicker back.
  int _indexAt(double x, double width) {
    var edge = 0.0;
    final slots = _slots(width, _shown);
    for (final (i, w) in slots.indexed) {
      edge += w;
      if (x < edge) return i;
    }
    return slots.length - 1;
  }

  void _press(double at) => setState(() => _down = at);

  /// [indexAt] finds the tab under a point along the bar.
  void _slide(double at, int Function(double) indexAt) {
    final down = _down;
    if (down == null) return;
    if (_hover == null && (at - down).abs() < barDragSlop) return;
    final i = indexAt(at);
    if (i == _hover) return;
    if (_hover != null || i != widget.shell.currentIndex) {
      HapticFeedback.selectionClick();
    }
    setState(() => _hover = i);
  }

  void _release(int Function(double) indexAt, {required bool commit}) {
    final down = _down;
    final target = _hover ?? (down == null ? null : indexAt(down));
    setState(() {
      _down = null;
      _hover = null;
    });
    if (!commit || target == null) return;
    if (target != widget.shell.currentIndex) HapticFeedback.selectionClick();
    _openTab(widget.shell, target);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = context.tones;
    final gray = Tone(
      scheme.surfaceContainerHigh,
      scheme.onSurface,
      scheme.onSurfaceVariant,
    );
    final List<_Tab> tabs = [
      (Icons.today_outlined, context.l10n.navToday, t.lilac, spikyStar),
      (Icons.forum_outlined, context.l10n.navMessages, t.sun, scallop),
      (
        Icons.calendar_view_week_outlined,
        context.l10n.navTimetable,
        t.mint,
        clover,
      ),
      (Icons.event_outlined, context.l10n.navCalendar, t.sun, scallop),
      (Icons.apps, context.l10n.navMore, gray, clover),
    ];
    final light = theme.brightness == Brightness.light;
    final pressed = _down != null;
    // Wide windows (desktop, iPad in landscape) trade the floating bar for
    // a sidebar; an iPad in portrait for a rail that opens the sidebar.
    final width = MediaQuery.sizeOf(context).width;
    // A foldable keeps the phone's bar: it is still held like a phone,
    // and its pages split at the fold instead.
    if (width >= railLayout && foldOf(context) == null) {
      final rail = width < wideLayout;
      void close() => setState(() => _expanded = false);
      _Sidebar side({required bool rail}) => _Sidebar(
        shell: widget.shell,
        tabs: [for (final t in tabs) (t.$1, t.$2)],
        course: int.tryParse(
          RegExp(r'^/courses/(\d+)').firstMatch(widget.location)?[1] ?? '',
        ),
        rail: rail,
        // Content width for the course pages: the window less the bar.
        content: width - (rail ? _railWidth : _sidebarWidth) - 1,
        onExpand: () => setState(() => _expanded = true),
        onPicked: close,
      );
      final open = rail && _expanded;
      return Scaffold(
        backgroundColor: scheme.surface,
        body: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                side(rail: rail),
                VerticalDivider(width: 1, color: scheme.outlineVariant),
                // On macOS the pages beside the sidebar take the title bar's
                // row: their titles line up with the window buttons.
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: Platform.isMacOS,
                    child: PaneSize(child: widget.shell),
                  ),
                ),
              ],
            ),
            if (rail) ...[
              IgnorePointer(
                ignoring: !open,
                child: GestureDetector(
                  onTap: close,
                  child: AnimatedOpacity(
                    opacity: open ? 1 : 0,
                    duration: barMove,
                    curve: barSettle,
                    child: const ColoredBox(
                      color: Colors.black38,
                      child: SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: barMove,
                curve: barSettle,
                top: 0,
                bottom: 0,
                left: open ? 0 : -_sidebarWidth - 32,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(color: Colors.black38, blurRadius: 32),
                    ],
                  ),
                  child: side(rail: false),
                ),
              ),
            ],
          ],
        ),
      );
    }
    // An iPhone Duo stands the bar upright on the right: on its outer
    // display, where the system keeps its own bars, and on the inner one
    // open in landscape (design/round-12 duo-variants B).
    final upright =
        barsOnRight(context) || foldOf(context)?.posture == FoldPosture.across;
    if (upright) {
      // Against the system's strip; the page's own margin keeps it off
      // the content.
      final media = MediaQuery.of(context);
      final edge = math.max(media.viewPadding.right, Space.s);
      final room = edge + _uprightWidth;
      int at(double y) => ((y - _uprightInset) / (_uprightSlot + _uprightGap))
          .floor()
          .clamp(0, tabs.length - 1);
      return Scaffold(
        backgroundColor: scheme.surface,
        body: Stack(
          children: [
            // The bar's room arrives as the right inset, like the bottom
            // bar's: app bars span the screen and keep their titles clear
            // of it, and pages pad their content by it (scrollPadding).
            MediaQuery(
              data: media.copyWith(
                padding: media.padding.copyWith(right: room),
                viewPadding: media.viewPadding.copyWith(right: room),
              ),
              child: widget.shell,
            ),
            Positioned(
              right: edge,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedScale(
                  scale: pressed ? 1.02 : 1,
                  duration: barMove,
                  curve: barSettle,
                  child: _GlassBar(
                    pressed: pressed,
                    light: light,
                    outline: scheme.outlineVariant,
                    upright: true,
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (e) => _press(e.localPosition.dy),
                      onPointerMove: (e) => _slide(e.localPosition.dy, at),
                      onPointerUp: (_) => _release(at, commit: true),
                      onPointerCancel: (_) => _release(at, commit: false),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: _uprightGap,
                        children: [
                          for (final (i, tab) in tabs.indexed)
                            _UprightSlot(tab: tab, selected: i == _shown),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    // Pages without an app bar (Today) still need status bar icons that
    // contrast with the edge-to-edge background.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
          ),
      child: Scaffold(
        // Content scrolls underneath; screens pad by the bottom media inset.
        extendBody: true,
        backgroundColor: scheme.surface,
        body: widget.shell,
        bottomNavigationBar: Padding(
          // Sit inside the home-indicator zone like the iOS floating tab bar
          // instead of stacking a full safe-area inset under it.
          padding: EdgeInsets.fromLTRB(
            Space.m,
            0,
            Space.m,
            // Android's gesture handle is drawn within its short inset, so
            // the bar stands above it there.
            theme.platform == TargetPlatform.android
                ? MediaQuery.viewPaddingOf(context).bottom + Space.s
                : math.max(
                    Space.s,
                    MediaQuery.viewPaddingOf(context).bottom - 18,
                  ),
          ),
          // A wide screen held like a phone (an open foldable) keeps the
          // bar at a phone's width.
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AnimatedScale(
                // Press: the bar lifts slightly; release springs back.
                scale: pressed ? 1.02 : 1,
                duration: barMove,
                curve: barSettle,
                child: _GlassBar(
                  pressed: pressed,
                  light: light,
                  outline: scheme.outlineVariant,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final w = box.maxWidth;
                      final n = tabs.length;
                      final style = DefaultTextStyle.of(context).style
                          .merge(_labelStyle);
                      final scaler = MediaQuery.textScalerOf(context);
                      _capsules = [
                        for (final (_, label, _, _) in tabs)
                          (TextPainter(
                                text: TextSpan(text: label, style: style),
                                textDirection: Directionality.of(context),
                                textScaler: scaler,
                                maxLines: 1,
                              )..layout()).width.ceilToDouble().clamp(
                                0,
                                w - (n - 1) * _minSlot - _capsuleChrome,
                              ) +
                              _capsuleChrome,
                      ];
                      final slots = _slots(w, _shown);
                      int at(double x) => _indexAt(x.clamp(0, w - 1), w);
                      return Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (e) => _press(e.localPosition.dx),
                        onPointerMove: (e) => _slide(e.localPosition.dx, at),
                        onPointerUp: (_) => _release(at, commit: true),
                        onPointerCancel: (_) => _release(at, commit: false),
                        child: Row(
                          children: [
                            for (final (i, tab) in tabs.indexed)
                              _TabSlot(
                                tab: tab,
                                width: slots[i],
                                selected: i == _shown,
                                pressed: pressed && i == _shown,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Switches to tab [i]; the tab already shown returns to its first page.
/// Pages pushed with [Navigator.push] (a mail, the compose screen) are not
/// go_router's, so they are popped here before go_router resets the tab;
/// its own pages are left for it, since popping them here would leave its
/// state behind what is on screen.
void _openTab(StatefulNavigationShell shell, int i) {
  final again = i == shell.currentIndex;
  if (again) {
    shell.route.branches[i].navigatorKey.currentState?.popUntil(
      (r) => r.settings is Page,
    );
  }
  shell.goBranch(i, initialLocation: again);
}

/// Desktop sidebar, design/round-11 desktop direction A: the five tabs, then
/// this semester's courses.
class _Sidebar extends StatefulWidget {
  const _Sidebar({
    required this.shell,
    required this.tabs,
    required this.rail,
    required this.content,
    required this.onExpand,
    required this.onPicked,
    this.course,
  });

  final StatefulNavigationShell shell;
  final List<(IconData, String)> tabs;

  /// Icons only (iPad in portrait, design/round-11 ipad-variants A); its
  /// top button opens the full sidebar over the page.
  final bool rail;

  /// Width the pages get beside this bar.
  final double content;

  final VoidCallback onExpand;

  /// After a tab or course is chosen, so the sidebar opened from the rail
  /// gets out of the way.
  final VoidCallback onPicked;

  /// The course whose pages are shown; it is lit along with its tab.
  final int? course;

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> with AutoRefresh {
  EcourseRepository? _repo;
  late Stream<(List<Course>, int)> _data;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = context.watch<EcourseRepository>();
    if (repo == _repo) return;
    _repo = repo;
    _load(repo);
  }

  void _load(EcourseRepository repo) {
    markAsked();
    // The pages show their own load errors; the sidebar just stays short.
    _data = repo.watch(
      (r) async => (
        await r.currentCourses(),
        await r.unreadNotices() + await r.unreadMail(),
      ),
    );
  }

  // The unread count keeps up like the pages ([AutoRefresh]).
  @override
  void refresh() {
    if (_repo case final repo?) setState(() => _load(repo));
  }

  /// A content area wide enough for list and detail opens the course with
  /// its sections beside it, in place of whatever course was open; a
  /// narrower one pushes the course page.
  void _openCourse(int id) {
    widget.onPicked();
    if (widget.content >= splitLayout) {
      context.go('/courses/$id/contents');
    } else if (widget.course == null) {
      context.push('/courses/$id');
    } else {
      context.pushReplacement('/courses/$id');
    }
  }

  void _goTab(int i) {
    widget.onPicked();
    _openTab(widget.shell, i);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rail) return _buildRail(context);
    final scheme = Theme.of(context).colorScheme;
    final t = context.tones;
    return Container(
      width: _sidebarWidth,
      color: scheme.surfaceContainer,
      padding: EdgeInsets.fromLTRB(
        Space.m,
        MediaQuery.paddingOf(context).top + Space.m,
        Space.m,
        Space.l,
      ),
      child: StreamBuilder(
        stream: _data,
        builder: (context, snap) {
          final (courses, unread) = snap.data ?? (const <Course>[], 0);
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              for (final (i, (icon, label)) in widget.tabs.indexed)
                _SideItem(
                  icon: icon,
                  label: label,
                  selected: i == widget.shell.currentIndex,
                  badge: i == 1 && unread > 0 ? '$unread' : null,
                  onTap: () => _goTab(i),
                ),
              if (courses.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.m, 18, Space.m, 6),
                  child: Text(
                    context.l10n.navCourses,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              for (final c in courses)
                PressFeedback(
                  scale: 0.97,
                  haptic: HapticFeedback.selectionClick,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openCourse(c.id),
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: c.id == widget.course
                            ? scheme.surfaceContainerHigh
                            : null,
                        borderRadius: BorderRadius.circular(Space.m),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: Space.m),
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: t.forCourse(c.id).strong,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.courseName(c),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: c.id == widget.course
                                    ? scheme.onSurface
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

extension on _SidebarState {
  Widget _buildRail(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = context.tones;
    Widget cell({
      required Widget child,
      required bool selected,
      required VoidCallback onTap,
      required String label,
      double height = 48,
    }) => Semantics(
      button: true,
      selected: selected,
      label: label,
      child: PressFeedback(
        scale: 0.94,
        haptic: HapticFeedback.selectionClick,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 48,
            height: height,
            margin: const EdgeInsets.only(bottom: Space.s),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? scheme.surfaceContainerHigh : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: child,
          ),
        ),
      ),
    );
    return Container(
      width: _railWidth,
      color: scheme.surfaceContainer,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + Space.m,
      ),
      child: StreamBuilder(
        stream: _data,
        builder: (context, snap) {
          final (courses, unread) = snap.data ?? (const <Course>[], 0);
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: Space.m),
            children: [
              cell(
                label: MaterialLocalizations.of(context).openAppDrawerTooltip,
                selected: false,
                onTap: widget.onExpand,
                child: Icon(
                  Icons.view_sidebar_outlined,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              for (final (i, (icon, label)) in widget.tabs.indexed)
                cell(
                  label: label,
                  selected: i == widget.shell.currentIndex,
                  onTap: () => _goTab(i),
                  child: Badge(
                    isLabelVisible: i == 1 && unread > 0,
                    smallSize: 8,
                    backgroundColor: t.sun.strong,
                    child: Icon(
                      icon,
                      color: i == widget.shell.currentIndex
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (courses.isNotEmpty)
                Center(
                  child: Container(
                    width: 28,
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: Space.s),
                    color: scheme.outlineVariant,
                  ),
                ),
              for (final c in courses)
                cell(
                  label: context.courseName(c),
                  height: 36,
                  selected: c.id == widget.course,
                  onTap: () => _openCourse(c.id),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: t.forCourse(c.id).strong,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sun = context.tones.sun;
    return Semantics(
      button: true,
      selected: selected,
      child: PressFeedback(
        scale: 0.97,
        haptic: HapticFeedback.selectionClick,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: Space.m),
            decoration: BoxDecoration(
              color: selected ? scheme.surfaceContainerHigh : null,
              borderRadius: BorderRadius.circular(Space.m),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (badge case final badge?)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: sun.strong,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: sun.fill,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Liquid-glass-style surface: the page shows through a frosted, tinted
/// layer with a bright rim on top, like the iOS 26 tab bar. Flutter has no
/// native Liquid Glass, so this approximates it with a backdrop blur.
class _GlassBar extends StatelessWidget {
  const _GlassBar({
    required this.pressed,
    required this.light,
    required this.outline,
    required this.child,
    this.upright = false,
  });

  final bool pressed, light, upright;
  final Color outline;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const shape = StadiumBorder();
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: pressed ? 0.22 : 0.14),
            blurRadius: pressed ? 36 : 28,
            offset: Offset(0, pressed ? 14 : 10),
          ),
        ],
      ),
      child: ClipPath(
        clipper: const ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: upright ? null : _barHeight,
            width: upright ? _uprightWidth : null,
            // Even inset on every side: (72 - 52) / 2.
            padding: EdgeInsets.all(upright ? _uprightInset : Space.m),
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: light
                    ? [const Color(0xCCFFFFFF), const Color(0x99FFFFFF)]
                    : [const Color(0x8C3A2F2B), const Color(0x73221A17)],
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: light
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.14),
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A tab of the upright bar: its icon only, on its tone when selected.
class _UprightSlot extends StatelessWidget {
  const _UprightSlot({required this.tab, required this.selected});

  final _Tab tab;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final (icon, label, tone, _) = tab;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: AnimatedContainer(
        duration: barMove,
        curve: barSettle,
        width: _uprightSlot,
        height: _uprightSlot,
        decoration: BoxDecoration(
          color: selected ? tone.fill : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: selected
              ? tone.ink
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TabSlot extends StatelessWidget {
  const _TabSlot({
    required this.tab,
    required this.width,
    required this.selected,
    required this.pressed,
  });

  final _Tab tab;
  final double width;
  final bool selected, pressed;

  @override
  Widget build(BuildContext context) {
    final (icon, label, tone, shape) = tab;
    final mute = Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: AnimatedContainer(
        duration: barMove,
        // No overshoot here: the slot widths must always sum to the bar.
        curve: barSettle,
        width: width,
        height: 52,
        // The capsule fills its slot so its inset matches the bar's, and the
        // icon sits as far from the capsule edge as from its top: (52-38)/2.
        padding: EdgeInsets.only(left: selected ? Space.s : 0),
        alignment: selected ? Alignment.centerLeft : Alignment.center,
        decoration: ShapeDecoration(
          // Pressing deepens the capsule so the finger has something to hold.
          color: selected
              ? Color.lerp(tone.fill, tone.strong, pressed ? 0.18 : 0)
              : Colors.transparent,
          shape: const StadiumBorder(),
        ),
        child: AnimatedScale(
          scale: pressed ? 1.03 : 1,
          duration: barMove,
          curve: barSettle,
          alignment: Alignment.centerLeft,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: barMove,
                    curve: barSettle,
                    width: selected ? 38 : 28,
                    height: selected ? 38 : 28,
                    decoration: ShapeDecoration(
                      color: selected ? tone.strong : Colors.transparent,
                      shape: shape,
                    ),
                    child: Icon(
                      icon,
                      size: selected ? 20 : 24,
                      color: selected ? tone.fill : mute,
                    ),
                  ),
                  ClipRect(
                    child: AnimatedSize(
                      duration: barMove,
                      curve: barSettle,
                      child: selected
                          ? Padding(
                              padding: const EdgeInsets.only(left: Space.s),
                              child: Text(
                                label,
                                maxLines: 1,
                                softWrap: false,
                                // Clips rather than wraps if the bar is too
                                // narrow for the whole label.
                                overflow: TextOverflow.fade,
                                style: _labelStyle.copyWith(color: tone.ink),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps every tab's navigator alive like an IndexedStack, but cross-fades
/// the incoming tab in with a slight rise instead of cutting to it.
class AnimatedBranches extends StatefulWidget {
  const AnimatedBranches({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<AnimatedBranches> createState() => _AnimatedBranchesState();
}

class _AnimatedBranchesState extends State<AnimatedBranches> {
  static const _duration = Duration(milliseconds: 260);

  /// The tab fading out; null once it is gone.
  int? _leaving;

  @override
  void didUpdateWidget(AnimatedBranches old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _leaving = old.index;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final (i, child) in widget.children.indexed)
          // Hidden tabs go offstage once faded: opacity does not hide a
          // platform view on Android, so a tab's web view would stay
          // drawn over the tab shown.
          Offstage(
            offstage: i != widget.index && i != _leaving,
            child: IgnorePointer(
              ignoring: i != widget.index,
              // The fade itself must keep ticking for the outgoing tab, or
              // it freezes half-visible over the new one; only the tab's own
              // content pauses.
              child: AnimatedOpacity(
                opacity: i == widget.index ? 1 : 0,
                duration: _duration,
                curve: barSettle,
                onEnd: () {
                  if (i == _leaving) setState(() => _leaving = null);
                },
                child: AnimatedSlide(
                  offset: i == widget.index
                      ? Offset.zero
                      : const Offset(0, 0.015),
                  duration: _duration,
                  curve: barSettle,
                  child: TickerMode(enabled: i == widget.index, child: child),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
