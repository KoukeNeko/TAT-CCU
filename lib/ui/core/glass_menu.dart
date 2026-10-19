import 'dart:async';
import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'theme.dart';
import '../../l10n/l10n.dart';

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
