import 'dart:async';
import 'dart:math' as math;
import 'dart:ui'
    show DisplayFeature, DisplayFeatureState, DisplayFeatureType, ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'command_palette.dart';
import 'desk_list.dart';
import 'desktop_mode.dart';
import 'floating_dock.dart';
import 'glass.dart';
import 'theme.dart';

export 'format.dart';
export 'glass_menu.dart';
export 'loader.dart';
export 'pull_refresh.dart';
export 'shapes.dart';

/// A bar action with the controls' press: themed buttons have their own
/// (button_press.dart), anything else sinks and ticks here.
Widget _pressable(Widget action) =>
    action is ButtonStyleButton ? action : PressFeedback(child: action);

/// Top-level tab title: large, no back button.
AppBar topBar(
  String title, {
  PreferredSizeWidget? bottom,
  List<Widget>? actions,
}) => AppBar(
  actions: [
    for (final a in actions ?? const <Widget>[]) _pressable(a),
    const _DesktopSearch(),
  ],
  automaticallyImplyLeading: false,
  backgroundColor: Colors.transparent,
  scrolledUnderElevation: 0,
  flexibleSpace: const GlassBackdrop(),
  // One line on a flip phone's outer display (design/round-24 flip-all).
  title: Builder(
    builder: (context) => Text(
      title,
      style: TextStyle(
        fontSize: coverScreen(context)
            ? 20
            : desktopUi(context)
            ? null
            : 34,
        fontWeight: FontWeight.w900,
      ),
    ),
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
/// Without [glass] only the buttons show, on the page itself; the glass
/// fades in when it is turned on.
AppBar subBar(
  BuildContext context,
  String title, {
  PreferredSizeWidget? bottom,
  Widget? action,
  bool glass = true,

  /// In place of [title]'s text, such as a menu of what the page shows.
  Widget? titleChild,
}) => AppBar(
  bottom: bottom,
  automaticallyImplyLeading: false,
  backgroundColor: Colors.transparent,
  scrolledUnderElevation: 0,
  flexibleSpace: AnimatedOpacity(
    opacity: glass ? 1 : 0,
    duration: const Duration(milliseconds: 200),
    child: const GlassBackdrop(),
  ),
  titleSpacing: 16,
  title: Row(
    children: [
      // A page opened beside a list (desktop) has nothing to go back to;
      // on a flip phone's outer display the rail has the back button.
      if (_canGoBack(context) && !coverScreen(context)) ...[
        RoundBackButton(),
        const SizedBox(width: 10),
      ],
      // A title that comes in later (the course page's, on scrolling)
      // rises and fades in with the glass rather than appearing at once.
      Expanded(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.centerLeft,
            children: [...previous, ?current],
          ),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.4),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: titleChild == null
              ? Text(
                  title,
                  key: ValueKey(title),
                  // One line on a flip phone's outer display.
                  maxLines: coverScreen(context) ? 1 : null,
                  overflow: coverScreen(context) ? TextOverflow.ellipsis : null,
                  style: coverScreen(context)
                      ? const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        )
                      : null,
                )
              : KeyedSubtree(key: ValueKey(title), child: titleChild),
        ),
      ),
      if (action != null) _pressable(action),
      const _DesktopSearch(),
    ],
  ),
);

/// The palette's field at the end of the desktop UI's rightmost bar.
class _DesktopSearch extends StatelessWidget {
  const _DesktopSearch();

  @override
  Widget build(BuildContext context) {
    if (!desktopUi(context) ||
        inLeadingPane(context) ||
        MediaQuery.sizeOf(context).width < 480) {
      return const SizedBox.shrink();
    }
    return const Padding(
      padding: EdgeInsets.only(left: Space.s, right: Space.s),
      child: PaletteField(),
    );
  }
}

/// The back button's feel for any app bar button: it sinks while pressed
/// and ticks. Listens to pointers only, so the button inside still gets
/// the tap.
class PressFeedback extends StatefulWidget {
  const PressFeedback({
    super.key,
    required this.child,
    this.scale = 0.88,
    this.enabled = true,
    this.haptic = HapticFeedback.lightImpact,
  });

  final Widget child;

  /// How far it sinks; wide controls sink less, or the motion is too big.
  final double scale;

  /// A disabled control neither sinks nor ticks.
  final bool enabled;

  /// The tick on touch-down; chips use the nav bar's lighter selection click.
  final Future<void> Function() haptic;

  @override
  State<PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<PressFeedback> {
  var _pressed = false;

  void _press(bool down) {
    if (!widget.enabled) return;
    if (down) widget.haptic();
    setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _press(true),
      onPointerUp: (_) => _press(false),
      onPointerCancel: (_) => _press(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutQuart,
        child: widget.child,
      ),
    );
  }
}

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
          popPage(context);
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

  /// A small bordered box in the desktop UI (design/round-25).
  static double heightOf(BuildContext context) =>
      desktopUi(context) ? 58 : height;

  final Tone tone;
  final IconData icon;
  final String title;
  final String? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    if (desktopUi(context)) {
      final scheme = Theme.of(context).colorScheme;
      return GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            height: heightOf(context),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (status != null)
                  Text(
                    status!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: tone.strong,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    // A flip phone's outer display keeps the name alone, in a short block
    // (design/round-24 flip-all).
    if (coverScreen(context)) {
      return SizedBox(
        height: 56,
        child: ToneBlock(
          tone: tone,
          padding: const EdgeInsets.all(Space.m),
          onTap: onTap,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              status ?? title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: ToneBlock(
        tone: tone,
        padding: cardPadding,
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
    this.padding = const EdgeInsets.all(Space.xl),
  });

  final Tone tone;
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (desktopUi(context)) {
      // design/round-25: a quiet box, its tone only an edge.
      final scheme = Theme.of(context).colorScheme;
      return Material(
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ColoredBox(color: tone.strong, child: const SizedBox(width: 3)),
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: tone.ink),
                    child: Padding(padding: padding, child: child),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
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
    if (desktopUi(context)) {
      // design/round-25: a small tag, lit like a list's chosen row.
      final ink = selected ? scheme.onSurface : scheme.onSurfaceVariant;
      return GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
          child: Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? deskSelection(scheme)
                  : scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                if (dropdown) Icon(Icons.expand_more, size: 15, color: ink),
              ],
            ),
          ),
        ),
      );
    }
    final ink = selected ? tone.fill : scheme.onSurfaceVariant;
    // Sinks and ticks like the app bar's buttons.
    return PressFeedback(
      scale: 0.92,
      enabled: onTap != null,
      haptic: HapticFeedback.selectionClick,
      child: Material(
        color: selected ? tone.strong : scheme.surfaceContainerHigh,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                Space.l,
                Space.s,
                dropdown ? Space.s : Space.l,
                Space.s,
              ),
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
      ),
    );
  }
}

/// A horizontally scrolling row of [BarChip]s, padded to the page margin.
class ChipRow extends StatelessWidget {
  const ChipRow({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: Space.l),
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
          padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.m),
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
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s,
          vertical: Space.xs,
        ),
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

/// The page's floating action, as 寫信: lilac-tinted liquid glass over the
/// list, like the nav bar and [FloatingDock], sinking with a tick.
class FloatingAction extends StatelessWidget {
  const FloatingAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.lilac;
    return PressFeedback(
      scale: 0.96,
      child: GlassSurface(
        radius: const BorderRadius.all(Radius.circular(28)),
        tint: tone.fill,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xl),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: tone.ink),
                  const SizedBox(width: Space.s),
                  Text(
                    label,
                    style: TextStyle(
                      color: tone.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A scrolling list with one action ([DockButton]) floating above the nav
/// bar, such as 送出 on a form; the list scrolls under it and ends clear.
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
            padding: padding.copyWith(
              bottom: bottom + FloatingDock.clearance + Space.l,
            ),
            children: children,
          ),
        ),
        Positioned(left: 0, right: 0, bottom: 0, child: action),
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
    final desk = desktopUi(context);
    final style = desk
        // design/round-25: a small heading over a rule.
        ? TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurfaceVariant,
          )
        : theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurfaceVariant,
          );
    return Container(
      margin: desk ? const EdgeInsets.only(top: Space.xxl) : null,
      decoration: desk
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            )
          : null,
      padding: desk
          ? const EdgeInsets.only(bottom: Space.xs)
          : const EdgeInsets.fromLTRB(
              Space.xs,
              sectionAbove,
              Space.xs,
              sectionBelow,
            ),
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
                    padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.padded,
                    textStyle: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
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
/// Room the upright nav bar takes at the right (iPhone Duo), for content
/// that reaches the right edge; a phone on its side has the same inset both
/// ways and stays centered.
double endInset(BuildContext context) {
  final inset = MediaQuery.paddingOf(context);
  return math.max(0, inset.right - inset.left);
}

/// The same at the left, where a flip phone's outer display has the bar.
double startInset(BuildContext context) {
  final inset = MediaQuery.paddingOf(context);
  return math.max(0, inset.left - inset.right);
}

EdgeInsets scrollPadding(
  BuildContext context, {
  double top = pageTop,
  double maxWidth = readableWidth,
}) {
  // Both bars float: the nav bar below and the glass app bar above arrive
  // as media padding when the body extends behind them.
  final inset = MediaQuery.paddingOf(context);
  final width = MediaQuery.sizeOf(context).width;
  if (desktopUi(context) && width >= splitLayout) {
    // design/round-25: from the page's left edge, as in Mail, up to a
    // readable width.
    const margin = 32.0;
    return EdgeInsets.fromLTRB(
      margin + startInset(context),
      top + inset.top,
      math.max(margin, width - margin - maxWidth) + endInset(context),
      Space.xxl + inset.bottom,
    );
  }
  // A wide area centers one readable column.
  final side = math.max(pageMargin, (width - maxWidth) / 2);
  return EdgeInsets.fromLTRB(
    side + startInset(context),
    top + inset.top,
    side + endInset(context),
    Space.xxl + inset.bottom,
  );
}

/// How a foldable phone's fold divides the screen (design/round-11
/// fold-variants B, duo-variants B): open like a book, pages put one half
/// on each side of it; half-open on a table, content goes above it and the
/// list below; an iPhone Duo open flat in landscape ([across]) puts
/// Today's class above it and stands the bar on the right.
enum FoldPosture { book, tabletop, across }

/// The fold across the screen and where it runs: its x for a book, its y
/// otherwise. Null on a flat screen. Another foldable open flat on its
/// side (the fold across) still reads as a book split down the middle,
/// keeping the phone's bar and the two halves.
({FoldPosture posture, double at})? foldOf(BuildContext context) {
  for (final f in MediaQuery.displayFeaturesOf(context)) {
    if (f.type == DisplayFeatureType.cutout) continue;
    final b = f.bounds;
    if (b.height > b.width) {
      return (posture: FoldPosture.book, at: b.center.dx);
    }
    if (f.state == DisplayFeatureState.postureHalfOpened) {
      return (posture: FoldPosture.tabletop, at: b.center.dy);
    }
    if (isPhoneDevice) return (posture: FoldPosture.across, at: b.center.dy);
    return (
      posture: FoldPosture.book,
      at: MediaQuery.sizeOf(context).width / 2,
    );
  }
  return null;
}

/// Whether the device is an iPhone, read once at launch; null elsewhere.
bool isPhoneDevice = false;

/// The fold of an iPhone Duo's inner display, which iOS does not report to
/// Flutter: it runs down the middle in portrait and across in landscape.
/// The inner display is the only iPhone screen 600 points or more on its
/// short side. Whether it is half open is not known, so it reads as flat.
// shortcut: assumes the fold is at the centre and the device open flat;
// read the iOS 27.1 fold geometry once the app builds with that SDK.
List<DisplayFeature> duoFold(MediaQueryData media) {
  if (!isPhoneDevice || media.size.shortestSide < 600) return const [];
  final size = media.size;
  return [
    DisplayFeature(
      bounds: size.width < size.height
          ? Rect.fromLTWH(size.width / 2, 0, 0, size.height)
          : Rect.fromLTWH(0, size.height / 2, size.width, 0),
      type: DisplayFeatureType.fold,
      state: DisplayFeatureState.postureFlat,
    ),
  ];
}

/// The system keeps its bars on the right edge (an iPhone Duo's outer
/// display, where the status bar and Dynamic Island move there), so the
/// app's own bar stands there too.
bool barsOnRight(BuildContext context) {
  final inset = MediaQuery.viewPaddingOf(context);
  return inset.right > inset.top && inset.right > inset.left;
}

/// A flip phone's outer display (Galaxy Z Flip, razr): small and nearly
/// square, unlike a phone held either way (design/round-24 C).
bool coverScreen(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.shortestSide < 480 &&
      size.aspectRatio > 0.75 &&
      size.aspectRatio < 1.34;
}

/// Space above a flip phone's outer display's rail and the home page's
/// first card: level with the title rows, (toolbar 56 - button 44) / 2.
const coverTop = 6.0;

/// Whether a list has its detail beside it: on a wide screen, or open as a
/// book, one on each side of the fold (an iPhone Duo's inner display is
/// narrower than [splitLayout]).
bool listBeside(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= splitLayout ||
    foldOf(context)?.posture == FoldPosture.book;

/// Width of the list beside its detail: up to the fold on a foldable,
/// otherwise the shared pane width.
double listWidthOf(BuildContext context) => switch (foldOf(context)) {
  (posture: FoldPosture.book, :final at) => at,
  _ => paneWidth,
};

/// Reports the area it is given as the media size, so a page laid out
/// beside the sidebar or a list measures its own column, not the window.
class PaneSize extends StatelessWidget {
  const PaneSize({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => MediaQuery(
      data: MediaQuery.of(context).copyWith(size: box.biggest),
      child: child,
    ),
  );
}

/// Marks a detail pane whose pages sit on the list's own route, [root],
/// which is hidden behind the list beside them (desktop 更多).
class ListPaneScope extends InheritedWidget {
  const ListPaneScope({super.key, required this.root, required super.child});

  final String root;

  @override
  bool updateShouldNotify(ListPaneScope old) => old.root != root;
}

/// Goes back a page. The first page of a nested navigator (a course, inside
/// the shell that sets it beside its lists on a desktop) cannot pop its own
/// navigator, so it leaves that shell through the router instead.
void popPage(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.maybePop();
  } else if (GoRouter.maybeOf(context) case final router?
      when router.canPop()) {
    router.pop();
  }
}

/// A page shows a back button when there is a page behind it to return
/// to, which is not so for the first page in a [ListPaneScope].
bool _canGoBack(BuildContext context) {
  final navigator = Navigator.of(context);
  if (!navigator.canPop()) return GoRouter.maybeOf(context)?.canPop() ?? false;
  final scope = context.getInheritedWidgetOfExactType<ListPaneScope>();
  if (scope == null) return true;
  final pages = navigator.widget.pages;
  final settings = ModalRoute.of(context)?.settings;
  // The list's own first page, shown beside it (a course's sections).
  if (settings is Page<Object?> && settings.name == scope.root) return false;
  final i = settings is Page<Object?> ? pages.indexOf(settings) : -1;
  return i < 1 || pages[i - 1].name != scope.root;
}

/// The page beside a list before anything is opened: on a desktop, only
/// its bar, which carries the search field.
class EmptyPane extends StatelessWidget {
  const EmptyPane({super.key});

  @override
  Widget build(BuildContext context) => desktopUi(context)
      ? Scaffold(appBar: subBar(context, ''))
      : const SizedBox.shrink();
}
