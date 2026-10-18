import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/ecourse_auth_repository.dart';

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
AppBar topBar(String title, {PreferredSizeWidget? bottom}) => AppBar(
  automaticallyImplyLeading: false,
  toolbarHeight: 76,
  title: Text(
    title,
    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
  ),
  bottom: bottom,
);

/// Sub-page title with the round back button from the mockup.
AppBar subBar(BuildContext context, String title) => AppBar(
  automaticallyImplyLeading: false,
  titleSpacing: 16,
  title: Row(
    children: [
      RoundBackButton(),
      const SizedBox(width: 10),
      Expanded(child: Text(title)),
    ],
  ),
);

class RoundBackButton extends StatelessWidget {
  const RoundBackButton({super.key, this.color, this.iconColor});

  final Color? color, iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: color ?? scheme.surfaceContainer,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).maybePop(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.chevron_left, color: iconColor ?? scheme.onSurface),
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

/// Loads [load] and renders [builder]; handles loading, error with retry and
/// pull-to-refresh so every screen behaves the same way.
class Loader<T> extends StatefulWidget {
  const Loader({super.key, required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;

  @override
  State<Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<Loader<T>> {
  late Future<T> _future = widget.load();

  Future<void> _reload() async {
    final next = widget.load();
    setState(() => _future = next);
    await next.catchError((_) => null as T);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('無法載入', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('${snap.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: _reload,
                    child: const Text('重試'),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _reload,
          child: widget.builder(context, snap.data as T),
        );
      },
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

const weekdayNames = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'];

String clock(int minutes) =>
    '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

String dateTimeLabel(DateTime t) =>
    '${t.month}/${t.day} ${weekdayNames[t.weekday - 1]} ${clock(t.hour * 60 + t.minute)}';

/// Opens an eCourse2 or campus page in the system browser, which shares the
/// sign-in made during the launch.php flow. No token is put in the URL.
Future<void> openExternal(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// Scroll padding that clears the floating nav bar: the shell extends its
/// body under the bar, so the bar's height arrives as bottom media padding.
EdgeInsets scrollPadding(BuildContext context, {double top = 16}) =>
    EdgeInsets.fromLTRB(16, top, 16, 24 + MediaQuery.paddingOf(context).bottom);

/// Opens a CAS-protected page in the same system sign-in sheet the eCourse2
/// login uses (ASWebAuthenticationSession / Custom Tabs), so the CAS sign-in
/// made there carries over. The portal never redirects to the app, so the
/// sheet only ends when the user closes it; that is not an error.
Future<void> openSignInSheet(String url) async {
  try {
    await FlutterWebAuth2.authenticate(
      url: url,
      callbackUrlScheme: callbackScheme,
    );
  } on PlatformException catch (e) {
    if (e.code != 'CANCELED') rethrow;
  }
}
