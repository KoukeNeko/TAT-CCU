import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_shell.dart';
import 'theme.dart';

/// A choice of two, as the timetable's 日 / 週: a track as tall as a bar
/// button, the chosen one in a [tone] capsule. Like the nav bar, the capsule
/// follows a finger dragged across, with a tick as it changes sides, and
/// the choice is made on release. [second] is whether the second is chosen.
class PairSwitch extends StatefulWidget {
  const PairSwitch({
    super.key,
    required this.labels,
    required this.second,
    required this.tone,
    required this.onChanged,
    this.segment = 44,
  });

  final (String, String) labels;
  final bool second;
  final Tone tone;
  final ValueChanged<bool> onChanged;

  /// Width of each side; wide enough for the longer label.
  final double segment;

  @override
  State<PairSwitch> createState() => _PairSwitchState();
}

class _PairSwitchState extends State<PairSwitch> {
  double get _segment => widget.segment;

  /// The side under the finger while one is down; null otherwise.
  bool? _hover;

  bool _sideAt(double x) => x - Space.xs >= _segment;

  void _move(double x) {
    final second = _sideAt(x);
    if (_hover == null || second == _hover) return;
    HapticFeedback.selectionClick();
    setState(() => _hover = second);
  }

  void _release({required bool commit}) {
    final second = _hover;
    setState(() => _hover = null);
    if (commit && second != null && second != widget.second) {
      widget.onChanged(second);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = widget.tone;
    final shown = _hover ?? widget.second;
    final pressed = _hover != null;
    Widget label(bool value, String text) => Semantics(
      button: true,
      selected: widget.second == value,
      child: SizedBox(
        width: _segment,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: barMove,
            curve: barSettle,
            style: DefaultTextStyle.of(context).style.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: shown == value ? tone.fill : scheme.onSurfaceVariant,
            ),
            child: Text(text),
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
            final second = _sideAt(e.localPosition.dx);
            if (second != widget.second) HapticFeedback.selectionClick();
            setState(() => _hover = second);
          },
          onPointerMove: (e) => _move(e.localPosition.dx),
          onPointerUp: (_) => _release(commit: true),
          onPointerCancel: (_) => _release(commit: false),
          child: Container(
            height: 40,
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
                  left: shown ? _segment : 0,
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
                  children: [
                    label(false, widget.labels.$1),
                    label(true, widget.labels.$2),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
