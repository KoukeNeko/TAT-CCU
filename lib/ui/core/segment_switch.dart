import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_shell.dart';
import 'theme.dart';

/// The app's one choice control, as the timetable's 日 / 週: a track as tall
/// as a bar button, the chosen option in a [tone] capsule. Like the nav bar,
/// the capsule follows a finger dragged across, with a tick as it changes
/// option, and the choice is made on release.
class SegmentSwitch extends StatefulWidget {
  const SegmentSwitch({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.tone,
    this.segment,
    this.disabled = const {},
  });

  final List<String> labels;

  /// Index into [labels].
  final int selected;
  final ValueChanged<int> onChanged;

  /// Lilac when not given.
  final Tone? tone;

  /// Width of each option, wide enough for the longest label; null shares
  /// the width the switch is given (settings and forms).
  final double? segment;

  /// Options shown but not available here: dimmed, and skipped by a finger.
  final Set<int> disabled;

  @override
  State<SegmentSwitch> createState() => _SegmentSwitchState();
}

class _SegmentSwitchState extends State<SegmentSwitch> {
  /// The option under the finger while one is down; null otherwise.
  int? _hover;
  var _segment = 0.0;

  int _at(double x) =>
      ((x - Space.xs) / _segment).floor().clamp(0, widget.labels.length - 1);

  void _move(double x) {
    final i = _at(x);
    if (_hover == null || i == _hover || widget.disabled.contains(i)) return;
    HapticFeedback.selectionClick();
    setState(() => _hover = i);
  }

  void _release({required bool commit}) {
    final i = _hover;
    setState(() => _hover = null);
    if (commit && i != null && i != widget.selected) widget.onChanged(i);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = widget.tone ?? context.tones.lilac;
    final shown = _hover ?? widget.selected;
    final pressed = _hover != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = widget.labels.length;
        _segment =
            widget.segment ?? (constraints.maxWidth - 2 * Space.xs) / count;
        Widget label(int i) => Semantics(
          button: true,
          selected: widget.selected == i,
          enabled: !widget.disabled.contains(i),
          child: SizedBox(
            width: _segment,
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: barMove,
                curve: barSettle,
                style: DefaultTextStyle.of(context).style.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: shown == i
                      ? tone.fill
                      : widget.disabled.contains(i)
                      ? scheme.onSurfaceVariant.withValues(alpha: 0.4)
                      : scheme.onSurfaceVariant,
                ),
                child: Text(
                  widget.labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
        return AnimatedScale(
          // Pressed, the switch lifts slightly, as the nav bar does.
          scale: pressed ? 1.04 : 1,
          duration: barMove,
          curve: barSettle,
          // Claims a sideways drag, so a page view behind the switch (the
          // Messages filters) does not swipe while the capsule follows it.
          child: GestureDetector(
            onHorizontalDragStart: (_) {},
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                final i = _at(e.localPosition.dx);
                if (widget.disabled.contains(i)) return;
                if (i != widget.selected) HapticFeedback.selectionClick();
                setState(() => _hover = i);
              },
              onPointerMove: (e) => _move(e.localPosition.dx),
              onPointerUp: (_) => _release(commit: true),
              onPointerCancel: (_) => _release(commit: false),
              child: Container(
                height: 40,
                width: _segment * count + 2 * Space.xs,
                padding: const EdgeInsets.all(Space.xs),
                decoration: ShapeDecoration(
                  color: scheme.surfaceContainer,
                  shape: const StadiumBorder(),
                ),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: barMove,
                      curve: barSettle,
                      left: shown * _segment,
                      top: 0,
                      bottom: 0,
                      width: _segment,
                      child: AnimatedContainer(
                        duration: barMove,
                        curve: barSettle,
                        decoration: ShapeDecoration(
                          // Held, the capsule deepens, like the nav bar's.
                          color: pressed
                              ? Color.lerp(tone.strong, tone.fill, 0.12)
                              : tone.strong,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [for (var i = 0; i < count; i++) label(i)],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
