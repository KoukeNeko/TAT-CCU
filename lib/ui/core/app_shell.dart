import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';
import 'widgets.dart';

typedef _Tab = (IconData icon, String label, Tone tone, ShapeBorder shape);

const _barHeight = 72.0;
const _activeWidth = 100.0;
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

  /// Tab slot under [x]; slots are laid out for the tab currently shown, so
  /// the widened capsule stays under the finger and does not flicker back.
  int _indexAt(double x, double width, int count) {
    final other = (width - _activeWidth) / (count - 1);
    var edge = 0.0;
    for (var i = 0; i < count; i++) {
      edge += i == _shown ? _activeWidth : other;
      if (x < edge) return i;
    }
    return count - 1;
  }

  void _press(double x) => setState(() => _downX = x);

  void _slide(double x, double width, int count) {
    final down = _downX;
    if (down == null) return;
    if (_hover == null && (x - down).abs() < _dragSlop) return;
    final i = _indexAt(x.clamp(0, width - 1), width, count);
    if (i == _hover) return;
    if (_hover != null || i != widget.shell.currentIndex) {
      HapticFeedback.selectionClick();
    }
    setState(() => _hover = i);
  }

  void _release(double width, int count, {required bool commit}) {
    final down = _downX;
    final target =
        _hover ?? (down == null ? null : _indexAt(down, width, count));
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
      (Icons.today_outlined, '今天', t.lilac, spikyStar),
      (Icons.calendar_view_week_outlined, '課表', t.mint, clover),
      (Icons.school_outlined, '課程', t.peach, scallop),
      (Icons.event_outlined, '行事曆', t.sun, scallop),
      (Icons.apps, '更多', gray, clover),
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
            12,
            0,
            12,
            math.max(8, MediaQuery.viewPaddingOf(context).bottom - 18),
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
                  final other = (w - _activeWidth) / (n - 1);
                  return Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) => _press(e.localPosition.dx),
                    onPointerMove: (e) => _slide(e.localPosition.dx, w, n),
                    onPointerUp: (_) => _release(w, n, commit: true),
                    onPointerCancel: (_) => _release(w, n, commit: false),
                    child: Row(
                      children: [
                        for (final (i, tab) in tabs.indexed)
                          _TabSlot(
                            tab: tab,
                            width: i == _shown ? _activeWidth : other,
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
            padding: const EdgeInsets.all(10),
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
        padding: EdgeInsets.only(left: selected ? 7 : 0),
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
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                label,
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  color: tone.ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
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
