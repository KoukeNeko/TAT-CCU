import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'glass.dart';
import 'theme.dart';

/// The app's one bottom sheet: a frosted panel floating above the home
/// indicator, in the nav bar's and [showGlassMenu]'s glass. It covers the
/// nav bar and rises with the keyboard, so sheets lay out only their
/// content. [title] and [action] (such as 完成) head it when given.
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
  Widget? action,

  /// For content that sets its own height, such as a long list.
  bool tall = false,
}) => showModalBottomSheet<T>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  elevation: 0,
  barrierColor: Colors.black.withValues(alpha: 0.3),
  builder: (context) => _GlassSheet(
    title: title,
    action: action,
    tall: tall,
    child: builder(context),
  ),
);

class _GlassSheet extends StatelessWidget {
  const _GlassSheet({
    required this.child,
    required this.tall,
    this.title,
    this.action,
  });

  final Widget child;
  final bool tall;
  final String? title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    // The sheet route drops the top inset; the window still has it.
    final top = MediaQueryData.fromView(View.of(context)).padding.top + 24;
    const radius = BorderRadius.all(Radius.circular(Corners.card + 8));
    // Like the nav bar: inside the home-indicator zone rather than above a
    // full safe-area inset; above the keyboard when it is up.
    final bottom = media.viewInsets.bottom > 0
        ? media.viewInsets.bottom + 8
        : math.max(8.0, media.viewPadding.bottom - 18);
    final panel = GlassSurface(
      radius: radius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: Space.s, bottom: Space.xs),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          if (title != null || action != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xl,
                Space.xs,
                Space.m,
                Space.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  ?action,
                ],
              ),
            ),
          if (tall) Expanded(child: child) else Flexible(child: child),
        ],
      ),
    );
    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      padding: EdgeInsets.fromLTRB(Space.s, top, Space.s, bottom),
      // The panel already floats clear of the keyboard and home indicator,
      // so the content needs neither inset.
      child: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: MediaQuery.removeViewInsets(
          context: context,
          removeBottom: true,
          child: tall
              ? SizedBox(
                  height: math.min(
                    media.size.height * 0.75,
                    media.size.height - top - bottom,
                  ),
                  child: panel,
                )
              : panel,
        ),
      ),
    );
  }
}
