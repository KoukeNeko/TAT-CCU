import 'dart:async';
import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// The menu's panel on its own and open, for the design language page;
/// it ignores taps, which would otherwise close the page.
class GlassMenuPanel<T> extends StatelessWidget {
  const GlassMenuPanel({
    super.key,
    required this.items,
    this.selected,
    this.title,
  });

  final List<GlassMenuItem<T>> items;
  final T? selected;
  final String? title;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      width: 260,
      child: _GlassPanel<T>(
        reveal: kAlwaysCompleteAnimation,
        title: title,
        items: items,
        selected: selected,
      ),
    ),
  );
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
              padding: const EdgeInsets.all(Space.s),
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
                        padding: const EdgeInsets.fromLTRB(
                          Space.l,
                          Space.s,
                          Space.l,
                          Space.s,
                        ),
                        child: Text(
                          title,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    _Rows<T>(items: items, selected: selected),
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

/// The menu's rows, picked the way the nav bar picks a tab: press, slide,
/// and the highlight follows the finger with a tick per row; letting go on
/// a row picks it, off the rows cancels.
class _Rows<T> extends StatefulWidget {
  const _Rows({required this.items, required this.selected});

  final List<GlassMenuItem<T>> items;
  final T? selected;

  @override
  State<_Rows<T>> createState() => _RowsState<T>();
}

class _RowsState<T> extends State<_Rows<T>> {
  late final _keys = [for (final _ in widget.items) GlobalKey()];

  /// The row under the finger while pressed.
  int? _hover;
  var _pressed = false;

  /// The row let go on: it stays lit while the menu closes, rather than
  /// the highlight jumping back to the old choice first.
  int? _picked;

  int? _rowAt(Offset global) {
    for (final (i, key) in _keys.indexed) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      if ((box.localToGlobal(Offset.zero) & box.size).contains(global)) {
        return i;
      }
    }
    return null;
  }

  // Haptics as the nav bar's: a selection click per new row, none on
  // touch-down.
  void _down(PointerDownEvent e) {
    setState(() {
      _pressed = true;
      _hover = _rowAt(e.position);
    });
  }

  void _move(PointerMoveEvent e) {
    final i = _rowAt(e.position);
    if (i == _hover) return;
    if (i != null) HapticFeedback.selectionClick();
    setState(() => _hover = i);
  }

  void _up(PointerUpEvent e) {
    final i = _rowAt(e.position);
    if (i == null) return _cancel(null);
    final value = widget.items[i].value;
    if (value != widget.selected) HapticFeedback.selectionClick();
    setState(() => _picked = i);
    Navigator.of(context).pop(value);
  }

  void _cancel(PointerCancelEvent? _) => setState(() {
    _pressed = false;
    _hover = null;
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chosen = widget.items.indexWhere((i) => i.value == widget.selected);
    final lit = _picked ?? (_pressed ? _hover : chosen);
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _cancel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, item) in widget.items.indexed)
            Semantics(
              button: true,
              selected: i == chosen,
              onTap: () => Navigator.of(context).pop(item.value),
              child: _row(
                context,
                key: _keys[i],
                item: item,
                lit: i == lit,
                checked: i == chosen,
                pressed: _pressed && _picked == null && i == _hover,
                scheme: scheme,
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required Key key,
    required GlassMenuItem<T> item,
    required bool lit,
    required bool checked,
    required bool pressed,
    required ColorScheme scheme,
  }) {
    final tone = context.tones.lilac;
    final ink = lit ? tone.ink : scheme.onSurface;
    return AnimatedScale(
      key: key,
      scale: pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutQuart,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutQuart,
        padding: EdgeInsets.symmetric(
          horizontal: item.icon == null ? Space.l : Space.m,
          vertical: item.icon == null ? Space.m : Space.s,
        ),
        decoration: BoxDecoration(
          color: lit ? tone.fill : tone.fill.withValues(alpha: 0),
          borderRadius: const BorderRadius.all(Radius.circular(Corners.row)),
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
                  fontWeight: lit ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
            if (item.detail case final detail?)
              Text(
                detail,
                style: TextStyle(
                  color: lit
                      ? tone.ink.withValues(alpha: 0.7)
                      : scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            if (widget.selected != null)
              SizedBox(
                width: 26,
                child: checked
                    ? Icon(Icons.check, size: 18, color: tone.strong)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
