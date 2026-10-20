import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// The app's frosted glass, as the nav bar and sheets use it: the page
/// blurred behind a translucent gradient with a light hairline edge.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.radius,
    required this.child,
    this.shadow = true,
    this.tint,
  });

  final BorderRadius radius;
  final Widget child;
  final bool shadow;

  /// Colors the glass, still letting the page show through.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          if (shadow)
            const BoxShadow(
              color: Color(0x40000000),
              blurRadius: 40,
              offset: Offset(0, 16),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: switch (tint) {
                  final t? => [
                    t.withValues(alpha: 0.88),
                    t.withValues(alpha: 0.72),
                  ],
                  null when light => [
                    const Color(0xE6FFFFFF),
                    const Color(0xC7FFFFFF),
                  ],
                  null => [const Color(0xB33A2F2B), const Color(0x99221A17)],
                },
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: light ? 0.95 : 0.14),
              ),
            ),
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ),
      ),
    );
  }
}
