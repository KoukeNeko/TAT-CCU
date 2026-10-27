import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';
import 'widgets.dart';

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
      // Merged, so the app's font carries through.
      child: DefaultTextStyle.merge(
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
    this.excerpt,
    this.trailing,
    this.selected = false,
    this.dimmed = false,
    this.onTap,
  });

  final Widget? leading, trailing;
  final String title;
  final String? subtitle;

  /// Two lines of the item's text between the title and [subtitle].
  final String? excerpt;
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
  void initState() {
    super.initState();
    if (widget.selected) _reveal();
  }

  @override
  void didUpdateWidget(DeskRow old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) _reveal();
  }

  /// Scrolls the lit row into its list, as Mail keeps the open message in
  /// view.
  /// Neither moves a row already in view.
  void _reveal() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    for (final policy in [
      ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    ]) {
      Scrollable.ensureVisible(context, alignmentPolicy: policy);
    }
  });

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
                    if (widget.excerpt case final excerpt?)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 3),
                        child: Text(
                          excerpt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                            color: muted,
                          ),
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
  const DeskTag(this.label, {super.key, this.color, this.tone});

  final String label;

  /// The label's colour on the neutral ground.
  final Color? color;

  /// Fills the tag with a state's tone instead, such as 已登入 in mint.
  final Tone? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tone?.fill ?? scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: _faint(scheme)
            .copyWith(color: tone?.ink ?? color ?? scheme.onSurfaceVariant),
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
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? detail, value;
  final Color? valueColor;

  /// After the value, such as a status tag or a button.
  final Widget? leading, trailing;
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
              if (trailing case final trailing?) ...[
                const SizedBox(width: Space.m),
                trailing,
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
    this.danger = false,
    this.trailingIcon,
  });

  /// After the label, such as ▾ on a button that opens a menu.
  final IconData? trailingIcon;

  final String label;
  final IconData? icon;
  final bool primary;

  /// Undoes something, such as cancelling a sign-up: its label in red.
  final bool danger;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = primary
        ? scheme.onPrimary
        : danger
        ? scheme.error
        : scheme.onSurface;
    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: onPressed == null
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        child: Opacity(
          // Unavailable until something is filled in or chosen.
          opacity: onPressed == null ? 0.45 : 1,
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
                if (trailingIcon case final icon?) ...[
                  const SizedBox(width: 4),
                  Icon(icon, size: 15, color: ink),
                ],
              ],
            ),
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

/// The desktop UI's icon square at the start of a line.
class DeskIcon extends StatelessWidget {
  const DeskIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 15, color: scheme.onSurfaceVariant),
    );
  }
}

/// The desktop UI's thin gauge.
class DeskBar extends StatelessWidget {
  const DeskBar({super.key, required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(3),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1),
      minHeight: 6,
      color: color,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    ),
  );
}

/// The desktop UI's choice of a few options on a track.
class DeskSegment extends StatelessWidget {
  const DeskSegment({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.disabled = const {},
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final Set<int> disabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          for (final (i, label) in labels.indexed)
            GestureDetector(
              onTap: disabled.contains(i) ? null : () => onChanged(i),
              child: MouseRegion(
                cursor: disabled.contains(i)
                    ? MouseCursor.defer
                    : SystemMouseCursors.click,
                child: Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? deskSelection(scheme) : null,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: i == selected
                          ? scheme.onSurface
                          : disabled.contains(i)
                          ? scheme.outline
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The desktop UI's switch, at a pointer's size.
class DeskToggle extends StatelessWidget {
  const DeskToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 30,
          height: 18,
          padding: const EdgeInsets.all(2),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: value ? scheme.onPrimary : scheme.onSurface,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// A desktop bar's path: [parent], which leads to [path], then [title].
AppBar deskCrumbBar(
  BuildContext context, {
  required String parent,
  required String path,
  required String title,
}) {
  final scheme = Theme.of(context).colorScheme;
  return subBar(
    context,
    title,
    back: false,
    titleChild: Row(
      children: [
        GestureDetector(
          onTap: () => context.go(path),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Text(
              parent,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            Icons.chevron_right,
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
