import 'package:flutter/material.dart';

import 'theme.dart';

/// The desktop UI's lists (design/round-25): Mail's dense rows in a list
/// column, and the sections of the page beside it.

/// The lit row's ground, between the selection colour and the page.
Color deskSelection(ColorScheme scheme) => Color.alphaBlend(
  scheme.primaryContainer.withValues(alpha: 0.6),
  scheme.surface,
);

TextStyle _faint(ColorScheme scheme) => TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w800,
  color: scheme.onSurfaceVariant,
);

/// A list column's group heading, with an optional count or link.
class DeskGroup extends StatelessWidget {
  const DeskGroup(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, 6),
      child: DefaultTextStyle(
        style: _faint(scheme),
        child: Row(children: [Text(title), const Spacer(), ?trailing]),
      ),
    );
  }
}

/// One row of a list column: [leading], the title over its [subtitle],
/// and [trailing]. It lights while [selected] and under the pointer.
class DeskRow extends StatefulWidget {
  const DeskRow({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.selected = false,
    this.dimmed = false,
    this.onTap,
  });

  final Widget? leading, trailing;
  final String title;
  final String? subtitle;
  final bool selected;

  /// Read, or already over: the title steps back.
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  State<DeskRow> createState() => _DeskRowState();
}

class _DeskRowState extends State<DeskRow> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: 9),
          decoration: BoxDecoration(
            color: widget.selected
                ? deskSelection(scheme)
                : _hover && widget.onTap != null
                ? scheme.surfaceContainer
                : null,
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Row(
            children: [
              if (widget.leading case final leading?) ...[
                leading,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: widget.dimmed && !widget.selected
                            ? FontWeight.w700
                            : FontWeight.w800,
                        color: widget.dimmed && !widget.selected
                            ? muted
                            : scheme.onSurface,
                      ),
                    ),
                    if (widget.subtitle case final subtitle?)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: muted,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.trailing case final trailing?) ...[
                const SizedBox(width: 10),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A row's coloured mark at its trailing edge, such as its course.
class DeskStripe extends StatelessWidget {
  const DeskStripe(this.color, {super.key});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 3,
    height: 30,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

/// A small label in a row, such as 上課中.
class DeskTag extends StatelessWidget {
  const DeskTag(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: _faint(scheme).copyWith(color: color ?? scheme.onSurfaceVariant),
      ),
    );
  }
}

/// A section of the page beside a list: its heading over a rule, with an
/// optional link at the end.
class DeskSection extends StatelessWidget {
  const DeskSection({
    super.key,
    required this.title,
    required this.children,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: Space.s),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Row(
            children: [
              Text(title, style: _faint(scheme).copyWith(fontSize: 12)),
              const Spacer(),
              if (action case final action?)
                GestureDetector(
                  onTap: onAction,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Text(
                      action,
                      style: _faint(scheme)
                          .copyWith(fontSize: 12, color: scheme.primary),
                    ),
                  ),
                ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

/// A line in a [DeskSection]: a title over its detail, a value at the end.
class DeskLine extends StatelessWidget {
  const DeskLine({
    super.key,
    required this.title,
    this.detail,
    this.value,
    this.valueColor,
    this.leading,
    this.onTap,
  });

  final String title;
  final String? detail, value;
  final Color? valueColor;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Row(
            children: [
              if (leading case final leading?) ...[
                leading,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (detail case final detail?)
                      Text(
                        detail,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (value case final value?) ...[
                const SizedBox(width: Space.m),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The desktop UI's button: 28 px, the pointer's size. [primary] fills it.
class DeskButton extends StatelessWidget {
  const DeskButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
  });

  final String label;
  final IconData? icon;
  final bool primary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = primary ? scheme.onPrimary : scheme.onSurface;
    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: Space.m),
          decoration: BoxDecoration(
            color: primary ? scheme.primary : scheme.surfaceContainerHigh,
            border: primary ? null : Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon case final icon?) ...[
                Icon(icon, size: 15, color: ink),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How long until the class starts or ends, round like a clock face.
class DeskCountdown extends StatelessWidget {
  const DeskCountdown({
    super.key,
    required this.color,
    required this.minutes,
    required this.done,
    required this.title,
    this.action,
    this.detail,
  });

  final Color color;
  final int minutes;

  /// How far through the class, 0–1.
  final double done;
  final String title;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: done.clamp(0, 1),
                  strokeWidth: 5,
                  color: color,
                  backgroundColor: scheme.surfaceContainerHigh,
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                ),
                Text(
                  '$minutes',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (detail case final detail?)
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
