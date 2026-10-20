import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Design S3's status capsule (design/round-11): a frosted pill under the
/// app bar saying what a page that already shows content is doing.
class StatusCapsule extends StatelessWidget {
  const StatusCapsule({
    super.key,
    required this.leading,
    required this.text,
    this.onTap,
  });

  /// 26 points square.
  final Widget leading;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const shape = StadiumBorder();
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipPath(
        clipper: const ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Material(
            color: scheme.surface.withValues(alpha: 0.72),
            shape: StadiumBorder(
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(dimension: 26, child: leading),
                    const SizedBox(width: 10),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where a [StatusCapsule] sits: under the app bar, sliding in from it and
/// back out when [capsule] turns null.
class CapsuleSlot extends StatelessWidget {
  const CapsuleSlot({super.key, this.capsule});

  final Widget? capsule;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 10,
      left: 16,
      right: 16,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, -0.4),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: capsule ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
