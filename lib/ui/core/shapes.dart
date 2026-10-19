import 'dart:math';

import 'package:flutter/material.dart';

import 'theme.dart';

/// Scalloped "cookie" outline from the Material 3 Expressive shape set:
/// a circle whose radius waves [lobes] times around the edge.
class CookieBorder extends OutlinedBorder {
  const CookieBorder({this.lobes = 9, this.depth = 0.08, super.side});

  final int lobes;
  final double depth;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final c = rect.center;
    final r = rect.shortestSide / 2 / (1 + depth);
    final path = Path();
    const steps = 180;
    for (var i = 0; i <= steps; i++) {
      final a = 2 * pi * i / steps - pi / 2;
      final rr = r * (1 + depth * cos(lobes * a));
      final p = c + Offset(cos(a), sin(a)) * rr;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  CookieBorder scale(double t) => this;

  @override
  CookieBorder copyWith({BorderSide? side}) =>
      CookieBorder(lobes: lobes, depth: depth, side: side ?? this.side);
}

/// Material 3 Expressive style loading indicator: a cookie that keeps
/// morphing between silhouettes while it turns. Flutter's material library
/// has no shape-morphing indicator yet, so the radii of two [CookieBorder]
/// outlines are blended directly.
class MorphingCookie extends StatefulWidget {
  const MorphingCookie({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  State<MorphingCookie> createState() => _MorphingCookieState();
}

class _MorphingCookieState extends State<MorphingCookie>
    with SingleTickerProviderStateMixin {
  /// (lobes, depth) silhouettes, visited in turn.
  static const _shapes = [
    (9, 0.08),
    (4, 0.14),
    (12, 0.05),
    (5, 0.12),
    (7, 0.1),
  ];
  static const _perShape = Duration(milliseconds: 700);

  late final _controller = AnimationController(
    vsync: this,
    duration: _perShape * _shapes.length,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final v = still ? 0.0 : _controller.value;
          final along = v * _shapes.length;
          final i = along.floor() % _shapes.length;
          // Morph in the first part of each slot, then hold; the overshoot
          // gives it the springy Expressive feel.
          final t = Curves.easeOutBack.transform(
            ((along - along.floor()) / 0.6).clamp(0.0, 1.0),
          );
          return CustomPaint(
            painter: _MorphPainter(
              from: _shapes[i],
              to: _shapes[(i + 1) % _shapes.length],
              t: t,
              turn: v * 2 * pi,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _MorphPainter extends CustomPainter {
  _MorphPainter({
    required this.from,
    required this.to,
    required this.t,
    required this.turn,
    required this.color,
  });

  final (int, double) from, to;
  final double t, turn;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final reach = 1 + max(from.$2, to.$2) * 1.2;
    final r = size.shortestSide / 2 / reach;
    final path = Path();
    const steps = 180;
    for (var k = 0; k <= steps; k++) {
      final a = 2 * pi * k / steps;
      final r0 = 1 + from.$2 * cos(from.$1 * a);
      final r1 = 1 + to.$2 * cos(to.$1 * a);
      final p =
          c + Offset(cos(a + turn), sin(a + turn)) * r * (r0 + (r1 - r0) * t);
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MorphPainter old) => true;
}

/// A number set inside a cookie shape; the app's signature badge.
class CookieBadge extends StatelessWidget {
  const CookieBadge({
    super.key,
    required this.value,
    this.unit,
    required this.color,
    required this.ink,
    this.size = 96,
    this.shape,
  });

  final String value;
  final String? unit;
  final Color color, ink;
  final double size;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: color,
        shape: shape ?? const CookieBorder(),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                color: ink,
                fontSize: size * 0.3,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          if (unit != null)
            Text(
              unit!,
              style: TextStyle(
                color: ink,
                fontSize: size * 0.12,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

/// Course avatar: a cookie with a lobe count derived from the course, so
/// each course has its own silhouette as well as its own color.
class CourseMark extends StatelessWidget {
  const CourseMark({super.key, required this.courseId, this.size = 44});

  final int courseId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.forCourse(courseId);
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: tone.strong,
        shape: courseShape(courseId),
      ),
    );
  }
}

/// Spiky star from the mockup's hero badge.
const spikyStar = StarBorder(
  points: 11,
  innerRadiusRatio: 0.78,
  pointRounding: 0.15,
  valleyRounding: 0.1,
);

/// Clover and scalloped cookie, the other two silhouettes in the mockup.
const clover = CookieBorder(lobes: 4, depth: 0.12);
const scallop = CookieBorder(lobes: 12, depth: 0.05);

/// Each course keeps one silhouette everywhere, alongside its color.
ShapeBorder courseShape(int courseId) =>
    const [spikyStar, clover, scallop][courseId % 3];
