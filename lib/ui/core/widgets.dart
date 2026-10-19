import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';

export 'format.dart';
export 'glass_menu.dart';
export 'loader.dart';
export 'shapes.dart';

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

/// A scrolling list with one full-width action pinned above the bottom
/// edge, such as 送出 on a form; the list scrolls clear of it.
class PinnedActionList extends StatelessWidget {
  const PinnedActionList({
    super.key,
    required this.padding,
    required this.action,
    required this.children,
  });

  final EdgeInsets padding;
  final Widget action;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        Positioned.fill(
          child: ListView(
            padding: padding.copyWith(bottom: bottom + 90),
            children: children,
          ),
        ),
        Positioned(
          left: pageMargin,
          right: pageMargin,
          bottom: bottom + 12,
          child: SizedBox(height: 54, child: action),
        ),
      ],
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
