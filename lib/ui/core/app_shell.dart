import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';
import 'widgets.dart';
import '../../l10n/l10n.dart';

typedef _Tab = (IconData icon, String label, Tone tone, ShapeBorder shape);

const _barHeight = 72.0;

/// Selected label style; the capsule is sized from it.
const _labelStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w900);

/// Left inset, icon, gap and right inset around the selected label; the
/// icon sits as far from the capsule edge as from its top: (52 - 38) / 2.
const _capsuleChrome = 7.0 + 38 + 8 + 16;

/// Narrowest an unselected slot gets, so long labels never squeeze icons.
const _minSlot = 44.0;
// Tuned toward SwiftUI's default spring: unhurried, settles without a
// visible bounce.
const _move = Duration(milliseconds: 480);
const _settle = Curves.easeOutQuart;

/// Finger travel before a press turns into a drag, so a tap never makes the
/// capsule jump around.
const _dragSlop = 12.0;

/// Floating nav bar, variant C3 "色塊膠囊" (design/round-04): only the
/// selected tab has color; it stretches into a capsule of its own function
/// color with its icon set inside its silhouette.
///
/// Like the iOS tab bar, a finger can press anywhere on the bar and slide
/// across it: the capsule follows the finger, each new tab ticks, and lifting
/// the finger commits the tab under it.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Where the finger went down; null when nothing is touching.
  double? _downX;

  /// Tab the capsule follows while dragging; null for a plain press.
  int? _hover;

  int get _shown => _hover ?? widget.shell.currentIndex;

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

  void _press(double x) => setState(() => _downX = x);

  void _slide(double x, double width) {
    final down = _downX;
    if (down == null) return;
    if (_hover == null && (x - down).abs() < _dragSlop) return;
    final i = _indexAt(x.clamp(0, width - 1), width);
    if (i == _hover) return;
    if (_hover != null || i != widget.shell.currentIndex) {
      HapticFeedback.selectionClick();
    }
    setState(() => _hover = i);
  }

  void _release(double width, {required bool commit}) {
    final down = _downX;
    final target = _hover ?? (down == null ? null : _indexAt(down, width));
    setState(() {
      _downX = null;
      _hover = null;
    });
    if (!commit || target == null) return;
    if (target != widget.shell.currentIndex) HapticFeedback.selectionClick();
    widget.shell.goBranch(
      target,
      initialLocation: target == widget.shell.currentIndex,
    );
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
    final pressed = _downX != null;
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
            math.max(Space.s, MediaQuery.viewPaddingOf(context).bottom - 18),
          ),
          child: AnimatedScale(
            // Press: the bar lifts slightly; release springs back.
            scale: pressed ? 1.02 : 1,
            duration: _move,
            curve: _settle,
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
                  return Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) => _press(e.localPosition.dx),
                    onPointerMove: (e) => _slide(e.localPosition.dx, w),
                    onPointerUp: (_) => _release(w, commit: true),
                    onPointerCancel: (_) => _release(w, commit: false),
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
  });

  final bool pressed, light;
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
            height: _barHeight,
            // Even inset on every side: (72 - 52) / 2.
            padding: const EdgeInsets.all(Space.m),
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
        duration: _move,
        // No overshoot here: the slot widths must always sum to the bar.
        curve: _settle,
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
          duration: _move,
          curve: _settle,
          alignment: Alignment.centerLeft,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: _move,
                    curve: _settle,
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
                      duration: _move,
                      curve: _settle,
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
class AnimatedBranches extends StatelessWidget {
  const AnimatedBranches({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  static const _duration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final (i, child) in children.indexed)
          IgnorePointer(
            ignoring: i != index,
            // The fade itself must keep ticking for the outgoing tab, or it
            // freezes half-visible over the new one; only the tab's own
            // content pauses.
            child: AnimatedOpacity(
              opacity: i == index ? 1 : 0,
              duration: _duration,
              curve: _settle,
              child: AnimatedSlide(
                offset: i == index ? Offset.zero : const Offset(0, 0.015),
                duration: _duration,
                curve: _settle,
                child: TickerMode(enabled: i == index, child: child),
              ),
            ),
          ),
      ],
    );
  }
}
