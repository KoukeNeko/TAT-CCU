import 'package:flutter/material.dart';

import 'glass.dart';
import 'theme.dart';
import 'widgets.dart';

/// A page's main action floating above the nav bar on glass, such as the
/// sign-up button or the reply field. Place it at the bottom of a Stack over
/// the content, which scrolls under it and ends [clearance] higher.
class FloatingDock extends StatelessWidget {
  const FloatingDock({
    super.key,
    required this.child,
    this.tone,
    this.enabled = true,
  });

  /// Bottom space a list under the dock leaves, besides the nav bar's.
  static const clearance = 88.0;

  final Widget child;

  /// The whole dock takes the action's color; its content uses the ink.
  final Tone? tone;

  /// Off for a dock whose action cannot be taken: it neither sinks nor
  /// ticks when pressed.
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      pageMargin,
      0,
      pageMargin,
      MediaQuery.paddingOf(context).bottom + Space.m,
    ),
    // The whole dock sinks and ticks when pressed, not just its content.
    child: PressFeedback(
      scale: 0.97,
      enabled: enabled,
      child: GlassSurface(
        radius: const BorderRadius.all(Radius.circular(Corners.card + 4)),
        tint: tone?.fill,
        child: Padding(padding: const EdgeInsets.all(Space.s), child: child),
      ),
    ),
  );
}

/// A page's one action as a [FloatingDock]: the dock takes [tone] and the
/// action is its text ([child]). Without [onPressed] the dock goes grey and
/// stays still.
class DockButton extends StatelessWidget {
  const DockButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.tone,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Tone? tone;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final tone = onPressed == null ? null : this.tone;
    return FloatingDock(
      tone: tone,
      enabled: onPressed != null,
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: tone?.ink ?? muted,
            // The dock itself shows the press; no overlay inside it.
            overlayColor: Colors.transparent,
            disabledForegroundColor: muted.withValues(alpha: 0.7),
            // Merged onto the theme's, so the label keeps the app's family.
            textStyle: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          child: child,
        ),
      ),
    );
  }
}
