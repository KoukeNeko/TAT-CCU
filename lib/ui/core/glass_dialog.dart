import 'package:flutter/material.dart';

import 'glass.dart';
import 'theme.dart';

/// The app's one dialog, in place of [showDialog]: a [GlassDialog] (or any
/// panel) that scales in over a light scrim, dismissed by tapping outside.
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: Colors.black.withValues(alpha: 0.24),
  transitionDuration: const Duration(milliseconds: 240),
  // No FadeTransition: an opacity layer above BackdropFilter keeps the
  // blur from painting until the fade ends.
  transitionBuilder: (context, animation, _, child) => ScaleTransition(
    scale: Tween(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuart)),
    child: child,
  ),
  pageBuilder: (context, _, _) => builder(context),
);

/// A glass panel with a [title], an optional [content] in the muted body
/// style, and its [actions] at the end: the cancel as a text button, the
/// action as a filled one (design/round-18 buttons A).
class GlassDialog extends StatelessWidget {
  const GlassDialog({
    super.key,
    required this.title,
    this.content,
    required this.actions,
  });

  final String title;
  final Widget? content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(pageMargin),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: GlassSurface(
            radius: BorderRadius.circular(Corners.card),
            child: Padding(
              padding: const EdgeInsets.all(Space.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  if (content != null) ...[
                    const SizedBox(height: Space.xs),
                    DefaultTextStyle.merge(
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      child: content!,
                    ),
                  ],
                  const SizedBox(height: Space.l),
                  // Tight buttons, so the panel's inset is the same on all
                  // sides.
                  Theme(
                    data: theme.copyWith(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      spacing: Space.s,
                      children: actions,
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
