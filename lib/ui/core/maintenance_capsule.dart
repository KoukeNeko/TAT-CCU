import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/services/ecourse_maintenance.dart';
import '../../l10n/l10n.dart';
import 'shapes.dart';
import 'status_capsule.dart';
import 'theme.dart';

/// Design A1 (design/round-11/maintenance-capsule-variants.html): while
/// eCourse2 is in maintenance, a ring around the cookie counts down to the
/// next check, the cookie morphs while checking, and a check mark shows
/// for a moment when it is [back]. Tapping checks at once.
class MaintenanceCapsule extends StatelessWidget {
  const MaintenanceCapsule({super.key, required this.back});

  final bool back;

  @override
  Widget build(BuildContext context) {
    final maintenance = EcourseMaintenance.instance;
    return ListenableBuilder(
      listenable: maintenance,
      builder: (context, _) {
        final l10n = context.l10n;
        final tones = context.tones;
        if (back) {
          return StatusCapsule(
            leading: DecoratedBox(
              decoration: BoxDecoration(
                color: tones.mint.strong,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, size: 18, color: tones.mint.fill),
            ),
            text: l10n.ecourseBack,
          );
        }
        if (maintenance.checking) {
          return StatusCapsule(
            leading: MorphingCookie(size: 26, color: tones.sun.strong),
            text: l10n.maintenanceChecking,
          );
        }
        return StatusCapsule(
          leading: _Countdown(
            next: maintenance.nextCheck,
            color: tones.sun.strong,
          ),
          text: l10n.ecourseInMaintenance,
          onTap: maintenance.check,
        );
      },
    );
  }
}

/// A still cookie inside a ring that fills up until [next].
class _Countdown extends StatelessWidget {
  const _Countdown({required this.next, required this.color});

  final DateTime? next;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final left = next?.difference(DateTime.now()) ?? Duration.zero;
    const total = EcourseMaintenance.interval;
    final start = 1 - (left.inMilliseconds / total.inMilliseconds).clamp(0, 1);
    return TweenAnimationBuilder<double>(
      key: ValueKey(next),
      tween: Tween(begin: start.toDouble(), end: 1),
      duration: left.isNegative ? Duration.zero : left,
      builder: (context, progress, child) => CustomPaint(
        painter: _Ring(progress: progress, color: color),
        child: child,
      ),
      child: Center(
        child: SizedBox.square(
          dimension: 16,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: const CookieBorder(lobes: 9, depth: 0.08),
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _Ring extends CustomPainter {
  _Ring({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawOval(rect, paint..color = color.withValues(alpha: 0.25));
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_Ring old) =>
      old.progress != progress || old.color != color;
}
