import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shapes.dart';
import 'theme.dart';

/// Pull to refresh with the app's own mark instead of Material's arrow: a
/// cookie under the app bar that grows and turns as the list is pulled,
/// fills in and ticks once letting go would refresh. The refresh itself
/// shows in the page's capsule, so [onRefresh] may return at once.
class PullRefresh extends StatefulWidget {
  const PullRefresh({super.key, required this.onRefresh, required this.child});

  final RefreshCallback onRefresh;
  final Widget child;

  @override
  State<PullRefresh> createState() => _PullRefreshState();
}

class _PullRefreshState extends State<PullRefresh> {
  /// How far the list is pulled, as a share of the distance that arms it.
  var _pull = 0.0;
  RefreshIndicatorStatus? _status;

  bool _track(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    // RefreshIndicator arms at a quarter of the viewport.
    final arm = n.metrics.viewportDimension * 0.25;
    final over = switch (n) {
      // iOS: the list bounces past its top.
      ScrollUpdateNotification() =>
        n.metrics.minScrollExtent - n.metrics.pixels,
      // Android: the list stays put and reports the overscroll.
      OverscrollNotification(:final overscroll) when overscroll < 0 =>
        _pull * arm - overscroll,
      ScrollEndNotification() => 0.0,
      _ => _pull * arm,
    };
    final pull = (over / arm).clamp(0.0, 1.4);
    if (pull != _pull) setState(() => _pull = pull);
    return false;
  }

  void _changed(RefreshIndicatorStatus? status) {
    if (status == RefreshIndicatorStatus.armed &&
        _status != RefreshIndicatorStatus.armed) {
      HapticFeedback.lightImpact();
    }
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.lilac;
    final armed =
        _status == RefreshIndicatorStatus.armed ||
        _status == RefreshIndicatorStatus.snap ||
        _status == RefreshIndicatorStatus.refresh;
    final shown = armed ? 1.0 : _pull.clamp(0.0, 1.0);
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _track,
          child: RefreshIndicator.noSpinner(
            onRefresh: widget.onRefresh,
            onStatusChange: _changed,
            child: widget.child,
          ),
        ),
        if (shown > 0)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 14,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Opacity(
                  opacity: shown,
                  child: Transform.rotate(
                    angle: _pull * pi,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 14 + 18 * shown,
                      height: 14 + 18 * shown,
                      decoration: ShapeDecoration(
                        color: armed
                            ? tone.strong
                            : tone.strong.withValues(alpha: 0.45),
                        shape: const CookieBorder(lobes: 9, depth: 0.1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
