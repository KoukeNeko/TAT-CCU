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

/// One choice in [showGlassMenu]; [detail] sits at the right end, and
/// [icon] shows in a [tone] square at the start.
typedef GlassMenuItem<T> = ({
  T value,
  String title,
  String? detail,
  IconData? icon,
  Tone? tone,
});

/// The app's one pop-up list (design/round-11, semester menu M1): a frosted
/// panel next to [anchor] whose chosen row is an inset capsule, so selection
/// and press highlights never touch the panel edge. Returns the tapped value,
/// or null when dismissed.
Future<T?> showGlassMenu<T>(
  BuildContext context, {
  required Rect anchor,
  required List<GlassMenuItem<T>> items,
  T? selected,
  String? title,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: context.l10n.close,
  barrierColor: Colors.black.withValues(alpha: 0.12),
  transitionDuration: const Duration(milliseconds: 240),
  // No FadeTransition: an opacity layer above BackdropFilter keeps the
  // blur from painting until the fade ends. The panel fades itself.
  transitionBuilder: (context, animation, _, child) => ScaleTransition(
    scale: Tween(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuart)),
    alignment: Alignment(
      anchor.center.dx / MediaQuery.sizeOf(context).width * 2 - 1,
      anchor.center.dy / MediaQuery.sizeOf(context).height * 2 - 1,
    ),
    child: child,
  ),
  pageBuilder: (context, animation, _) => CustomSingleChildLayout(
    delegate: _MenuLayout(anchor),
    child: _GlassPanel(
      reveal: CurvedAnimation(parent: animation, curve: Curves.easeOutQuart),
      title: title,
      items: items,
      selected: selected,
    ),
  ),
);

/// Below the anchor when it fits, otherwise above; lined up with the
/// anchor's nearer side.
class _MenuLayout extends SingleChildLayoutDelegate {
  _MenuLayout(this.anchor);

  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.tightFor(
        width: min(260, constraints.maxWidth - 2 * pageMargin),
      );

  @override
  Offset getPositionForChild(Size size, Size child) {
    final x = anchor.center.dx > size.width / 2
        ? anchor.right - child.width
        : anchor.left;
    final below = anchor.bottom + rowGap;
    final y = below + child.height <= size.height - 100
        ? below
        : anchor.top - rowGap - child.height;
    return Offset(
      x.clamp(pageMargin, size.width - pageMargin - child.width),
      max(y, pageMargin),
    );
  }

  @override
  bool shouldRelayout(_MenuLayout old) => old.anchor != anchor;
}

class _GlassPanel<T> extends StatelessWidget {
  const _GlassPanel({
    required this.reveal,
    required this.title,
    required this.items,
    required this.selected,
  });

  final Animation<double> reveal;
  final String? title;
  final List<GlassMenuItem<T>> items;
  final T? selected;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: reveal,
    builder: (context, _) => _panel(context),
  );

  Widget _panel(BuildContext context) {
    final t = reveal.value;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    const radius = BorderRadius.all(Radius.circular(Corners.card));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2 * t),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24 * t, sigmaY: 24 * t),
          child: Opacity(
            opacity: t,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: radius,
                color: light
                    ? Colors.white.withValues(alpha: 0.78)
                    : const Color(0x9E3A2F2B),
                border: Border.all(
                  color: Colors.white.withValues(alpha: light ? 0.95 : 0.14),
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title case final title?)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                        child: Text(
                          title,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    for (final item in items)
                      _row(context, item, item.value == selected, scheme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    GlassMenuItem<T> item,
    bool chosen,
    ColorScheme scheme,
  ) {
    final tone = context.tones.lilac;
    final ink = chosen ? tone.ink : scheme.onSurface;
    return Material(
      color: chosen ? tone.fill : Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(Corners.row)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(item.value),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: item.icon == null ? 14 : 10,
            vertical: item.icon == null ? 13 : 8,
          ),
          child: Row(
            children: [
              if (item.icon case final icon?) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (item.tone ?? tone).fill,
                    borderRadius: BorderRadius.circular(Corners.small),
                  ),
                  child: Icon(icon, size: 20, color: (item.tone ?? tone).ink),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: chosen ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
              if (item.detail case final detail?)
                Text(
                  detail,
                  style: TextStyle(
                    color: chosen
                        ? tone.ink.withValues(alpha: 0.7)
                        : scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              if (selected != null)
                SizedBox(
                  width: 26,
                  child: chosen
                      ? Icon(Icons.check, size: 18, color: tone.strong)
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sub-page title with the round back button from the mockup.
/// [action] sits at the title row's end, such as a capsule to another page.
AppBar subBar(
  BuildContext context,
  String title, {
  PreferredSizeWidget? bottom,
  Widget? action,
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
      ?action,
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

/// A status tile: the page's state large, its name small; the name alone
/// when there is no state to show. Shared by 今天 and 更多.
class StatusTile extends StatelessWidget {
  const StatusTile({
    super.key,
    required this.tone,
    required this.icon,
    required this.title,
    required this.onTap,
    this.status,
  });

  static const height = 120.0;

  final Tone tone;
  final IconData icon;
  final String title;
  final String? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return SizedBox(
      height: height,
      child: ToneBlock(
        tone: tone,
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: light ? 0.6 : 0.12),
                    borderRadius: BorderRadius.circular(Corners.small),
                  ),
                  child: Icon(icon, size: 20, color: tone.ink),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: tone.ink.withValues(alpha: 0.6),
                ),
              ],
            ),
            const Spacer(),
            Text(
              status ?? title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            if (status != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tone.ink.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
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
    this.radius = Corners.card,
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

/// The app's one chip (design: course contents bar): a pill that fills with
/// the tone's strong color when selected. [dropdown] adds a chevron for
/// chips that open a choice.
class BarChip extends StatelessWidget {
  const BarChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.tone,
    this.dropdown = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Defaults to lilac.
  final Tone? tone;
  final bool dropdown;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = this.tone ?? context.tones.lilac;
    final ink = selected ? tone.fill : scheme.onSurfaceVariant;
    return Material(
      color: selected ? tone.strong : scheme.surfaceContainerHigh,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, 9, dropdown ? 8 : 14, 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                ),
                if (dropdown) Icon(Icons.expand_more, size: 18, color: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A horizontally scrolling row of [BarChip]s, padded to the page margin.
class ChipRow extends StatelessWidget {
  const ChipRow({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // Full width, so a centring parent such as a Column keeps the chips at
    // the start.
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(
          children: [
            for (final (i, chip) in children.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              chip,
            ],
          ],
        ),
      ),
    );
  }
}

/// [ChipRow] as an app bar's bottom.
class ChipBar extends StatelessWidget implements PreferredSizeWidget {
  const ChipBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 52,
        child: ChipRow(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          children: children,
        ),
      ),
    );
  }
}

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

/// Small uppercase-style section label above a group of blocks.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.detail, this.action});

  final String text;

  /// Right-aligned, in the label's style: a count.
  final String? detail;

  /// Right-aligned button, such as 全部 or 編輯.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, sectionAbove, 4, sectionBelow),
      // One height with or without a button, so sections line up.
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
            if (detail case final d?) Text(d, style: style),
            if (action case final a?)
              TextButtonTheme(
                data: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.padded,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                child: a,
              ),
          ],
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
  Loader({
    super.key,
    required Future<T> Function() load,
    required this.builder,
    this.bar,
  }) : watch = (() => Stream.fromFuture(load()));

  const Loader.watch({
    super.key,
    required this.watch,
    required this.builder,
    this.bar,
  });

  final Stream<T> Function() watch;
  final Widget Function(BuildContext context, T data) builder;

  /// For a route that is a bare Loader: the app bar to show while loading,
  /// so the back button and title arrive with the route, not after it.
  final PreferredSizeWidget Function(BuildContext context)? bar;

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
      final bar = widget.bar;
      final body = error == null
          ? const LoadingView()
          : Center(
              child: Padding(
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
            );
      return bar == null
          ? Material(color: Theme.of(context).colorScheme.surface, child: body)
          : Scaffold(
              extendBodyBehindAppBar: true,
              appBar: bar(context),
              body: body,
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

/// A page loading (design S2-C): the morphing shape in the middle and what
/// is happening in large type near the thumb. With [steps], also the step
/// count and a bar of parts; only for loads that really go in steps.
class LoadingView extends StatelessWidget {
  const LoadingView({
    super.key,
    this.title,
    this.detail,
    this.step = 0,
    this.steps,
    this.action,
  });

  /// Defaults to 讀取資料.
  final String? title;
  final String? detail;

  /// Zero-based, out of [steps].
  final int step;
  final int? steps;

  /// A button under the bar, e.g. to show a page that needs the user.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final steps = this.steps;
    final title = this.title ?? context.l10n.campusReading;
    return ColoredBox(
      color: scheme.surface,
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(0, -0.25),
            child: MorphingCookie(size: 170, color: tones.lilac.fill),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.paddingOf(context).bottom + 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (steps != null) ...[
                  Text(
                    '${step + 1} / $steps',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.bottomLeft,
                    children: [...previous, ?current],
                  ),
                  child: Text(
                    title,
                    key: ValueKey(title),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (detail case final d? when d.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    d,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (steps != null) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      for (var i = 0; i < steps; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: i < step
                                  ? tones.mint.strong
                                  : i == step
                                  ? tones.lilac.strong
                                  : scheme.surfaceContainerHigh,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (action case final a?) ...[const SizedBox(height: 18), a],
              ],
            ),
          ),
        ],
      ),
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
EdgeInsets scrollPadding(BuildContext context, {double top = pageTop}) {
  // Both bars float: the nav bar below and the glass app bar above arrive
  // as media padding when the body extends behind them.
  final inset = MediaQuery.paddingOf(context);
  return EdgeInsets.fromLTRB(
    pageMargin,
    top + inset.top,
    pageMargin,
    24 + inset.bottom,
  );
}
