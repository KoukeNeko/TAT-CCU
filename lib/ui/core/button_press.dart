import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Every button's press (design/round-18 A): the capsule draws in by
/// [pressInset] and its color deepens, with a light tick. The theme gives
/// the shape per state; Material animates between the two.
const pressInset = 2.0;

/// A stadium drawn [inset] inside its box, so a pressed button looks to
/// sink while its tap area and label stay put.
class PressStadiumBorder extends OutlinedBorder {
  const PressStadiumBorder({super.side, this.inset = 0});

  final double inset;

  static const _stadium = StadiumBorder();

  Rect _inner(Rect rect) => rect.deflate(inset);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _stadium.getOuterPath(_inner(rect), textDirection: textDirection);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _stadium
      .copyWith(side: side)
      .getInnerPath(_inner(rect), textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) =>
      _stadium
          .copyWith(side: side)
          .paint(canvas, _inner(rect), textDirection: textDirection);

  @override
  ShapeBorder scale(double t) =>
      PressStadiumBorder(side: side.scale(t), inset: inset * t);

  @override
  OutlinedBorder copyWith({BorderSide? side, double? inset}) =>
      PressStadiumBorder(side: side ?? this.side, inset: inset ?? this.inset);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is PressStadiumBorder
      ? PressStadiumBorder(
          side: BorderSide.lerp(a.side, side, t),
          inset: lerpDouble(a.inset, inset, t)!,
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is PressStadiumBorder
      ? PressStadiumBorder(
          side: BorderSide.lerp(side, b.side, t),
          inset: lerpDouble(inset, b.inset, t)!,
        )
      : super.lerpTo(b, t);

  @override
  bool operator ==(Object other) =>
      other is PressStadiumBorder && other.side == side && other.inset == inset;

  @override
  int get hashCode => Object.hash(side, inset);
}

/// The shape per state: drawn in while pressed.
final pressShape = WidgetStateProperty.resolveWith<OutlinedBorder>(
  (states) => PressStadiumBorder(
    inset: states.contains(WidgetState.pressed) ? pressInset : 0,
  ),
);

/// For [ButtonStyle.backgroundBuilder]: ticks once as a press begins.
Widget pressHaptic(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) => _PressHaptic(
  pressed:
      states.contains(WidgetState.pressed) &&
      !states.contains(WidgetState.disabled),
  child: child,
);

class _PressHaptic extends StatefulWidget {
  const _PressHaptic({required this.pressed, required this.child});

  final bool pressed;
  final Widget? child;

  @override
  State<_PressHaptic> createState() => _PressHapticState();
}

class _PressHapticState extends State<_PressHaptic> {
  @override
  void didUpdateWidget(_PressHaptic old) {
    super.didUpdateWidget(old);
    if (widget.pressed && !old.pressed) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox();
}
