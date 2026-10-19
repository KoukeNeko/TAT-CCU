import 'dart:async';
import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';
import '../../l10n/l10n.dart';

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
    this.lobes = 9,
    this.shape,
  });

  final String value;
  final String? unit;
  final Color color, ink;
  final double size;
  final int lobes;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: color,
        shape: shape ?? CookieBorder(lobes: lobes),
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

/// Top-level tab title: large, no back button.
AppBar topBar(
  String title, {
  PreferredSizeWidget? bottom,
  List<Widget>? actions,
}) => AppBar(
  actions: actions,
  automaticallyImplyLeading: false,
  backgroundColor: Colors.transparent,
  scrolledUnderElevation: 0,
  flexibleSpace: const GlassBackdrop(),
  toolbarHeight: 76,
  title: Text(
    title,
    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
  ),
  bottom: bottom,
);

/// Frosted surface behind the shared app bars, matching the nav bar's
/// liquid-glass look. Screens extend their body behind the bar so content
/// scrolls underneath it.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Expand: a childless box would size itself to zero in the app bar.
    return SizedBox.expand(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.72),
              border: Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sub-page title with the round back button from the mockup.
AppBar subBar(
  BuildContext context,
  String title, {
  PreferredSizeWidget? bottom,
}) => AppBar(
  bottom: bottom,
  automaticallyImplyLeading: false,
  backgroundColor: Colors.transparent,
  scrolledUnderElevation: 0,
  flexibleSpace: const GlassBackdrop(),
  titleSpacing: 16,
  title: Row(
    children: [
      RoundBackButton(),
      const SizedBox(width: 10),
      Expanded(child: Text(title)),
    ],
  ),
);

/// Round back button: sinks and darkens while pressed and ticks when it
/// goes back, matching the nav bar's feel.
class RoundBackButton extends StatefulWidget {
  const RoundBackButton({super.key, this.color, this.iconColor});

  final Color? color, iconColor;

  @override
  State<RoundBackButton> createState() => _RoundBackButtonState();
}

class _RoundBackButtonState extends State<RoundBackButton> {
  var _pressed = false;

  void _press(bool down) => setState(() => _pressed = down);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = widget.color ?? scheme.surfaceContainer;
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapCancel: () => _press(false),
        onTapUp: (_) => _press(false),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).maybePop();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.86 : 1,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutQuart,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutQuart,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _pressed
                  ? Color.alphaBlend(
                      scheme.onSurface.withValues(alpha: 0.12),
                      fill,
                    )
                  : fill,
            ),
            child: Icon(
              Icons.chevron_left,
              color: widget.iconColor ?? scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded color block; the basic surface of direction C.
class ToneBlock extends StatelessWidget {
  const ToneBlock({
    super.key,
    required this.tone,
    required this.child,
    this.onTap,
    this.radius = 28,
    this.padding = const EdgeInsets.all(18),
  });

  final Tone tone;
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tone.fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: tone.ink),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Small uppercase-style section label above a group of blocks.
/// Small colored status capsule at the end of a list row.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.tone, required this.label});

  final Tone tone;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: tone.fill,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: tone.ink,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Loads data and renders [builder]; handles loading, error with retry and
/// pull-to-refresh so every screen behaves the same way.
///
/// [Loader.watch] takes a stream instead, such as
/// [EcourseRepository.watch]'s saved result followed by the fresh one: the
/// screen shows the first value at once and updates when the next arrives.
/// If refreshing fails after something is shown, it stays and a snack bar
/// says so.
class Loader<T> extends StatefulWidget {
  Loader({super.key, required Future<T> Function() load, required this.builder})
    : watch = (() => Stream.fromFuture(load()));

  const Loader.watch({super.key, required this.watch, required this.builder});

  final Stream<T> Function() watch;
  final Widget Function(BuildContext context, T data) builder;

  @override
  State<Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<Loader<T>> {
  StreamSubscription<T>? _sub;
  T? _data;
  var _hasData = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _start() {
    _sub?.cancel();
    final done = Completer<void>();
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    _sub = widget.watch().listen(
      (value) => setState(() {
        _data = value;
        _hasData = true;
        _error = null;
      }),
      onError: (Object e) {
        if (!mounted) return;
        if (_hasData) {
          ScaffoldMessenger.maybeOf(context)
              ?.showSnackBar(SnackBar(content: Text(context.l10n.loadFailed)));
        } else {
          setState(() => _error = e);
        }
        finish();
      },
      onDone: finish,
      cancelOnError: true,
    );
    return done.future;
  }

  void _retry() {
    setState(() => _error = null);
    _start();
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    // Some routes are a bare Loader until their data arrives; an opaque
    // surface keeps the previous page from showing through the incoming
    // route's transition.
    if (!_hasData) {
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: error == null
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.loadFailed,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text('$error', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: _retry,
                        child: Text(context.l10n.retry),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }
    return RefreshIndicator(
      // Bodies extend under the glass app bar; start the spinner below it.
      edgeOffset: MediaQuery.paddingOf(context).top,
      onRefresh: _start,
      child: widget.builder(context, _data as T),
    );
  }
}

/// Centered single-line state for empty lists.
class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: CookieBadge(
            value: '0',
            color: tones.lilac.fill,
            ink: tones.lilac.ink,
            size: 88,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}

/// `週一`, `Mon`, `月曜` for weekday 1–7.
String weekdayName(BuildContext context, int weekday) =>
    context.l10n.weekdayFull('$weekday');

/// `115_1` → `115 學年上學期`, `Fall of year 115`, `115学年度 前期`.
String semesterName(BuildContext context, String semester) {
  final parts = semester.split('_');
  if (parts.length < 2) return semester;
  return context.l10n.semesterLabel(parts[0], parts[1]);
}

/// `一`, `Mon`, `月` for weekday 1–7.
String weekdayShort(BuildContext context, int weekday) =>
    context.l10n.weekdayShort('$weekday');

String clock(int minutes) =>
    '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

String dateTimeLabel(BuildContext context, DateTime t) =>
    '${t.month}/${t.day} ${weekdayName(context, t.weekday)} ${clock(t.hour * 60 + t.minute)}';

/// Opens an eCourse2 or campus page in the system browser, which shares the
/// sign-in made during the launch.php flow. No token is put in the URL.
Future<void> openExternal(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// Scroll padding that clears the floating nav bar: the shell extends its
/// body under the bar, so the bar's height arrives as bottom media padding.
/// [top] is the gap below the app bar; one value so every page starts at
/// the same height.
EdgeInsets scrollPadding(BuildContext context, {double top = 12}) {
  // Both bars float: the nav bar below and the glass app bar above arrive
  // as media padding when the body extends behind them.
  final inset = MediaQuery.paddingOf(context);
  return EdgeInsets.fromLTRB(16, top + inset.top, 16, 24 + inset.bottom);
}
