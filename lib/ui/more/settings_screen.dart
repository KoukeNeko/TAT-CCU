import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/app_settings.dart';
import '../../l10n/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// Design S2 "直接選" (design/round-11): theme as three preview cards and
/// language as one segmented row; a tap applies at once.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<AppSettings>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, l10n.settings),
      body: Builder(
        // Reads insets from inside this Scaffold, below the glass app bar.
        builder: (context) => ListView(
          padding: scrollPadding(context, top: 0),
          children: [
            SectionLabel(l10n.appearance),
            Row(
              children: [
                for (final (i, (mode, label)) in [
                  (ThemeMode.system, l10n.followSystem),
                  (ThemeMode.light, l10n.themeLight),
                  (ThemeMode.dark, l10n.themeDark),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: rowGap),
                  Expanded(
                    child: _ThemeCard(
                      mode: mode,
                      label: label,
                      selected: settings.themeMode == mode,
                      onTap: () => settings.setThemeMode(mode),
                    ),
                  ),
                ],
              ],
            ),
            SectionLabel(l10n.language),
            _Segments(
              selected: settings.locale?.languageCode,
              options: [
                (null, l10n.followSystem),
                // Each language is named in itself so it can be found from
                // any of the others.
                ('zh', '繁中'),
                ('en', 'English'),
                ('ja', '日本語'),
              ],
              onSelected: (code) =>
                  settings.setLocale(code == null ? null : Locale(code)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = switch (mode) {
      ThemeMode.light => const _Mini(Brightness.light),
      ThemeMode.dark => const _Mini(Brightness.dark),
      // Half light, half dark.
      ThemeMode.system => Stack(
        children: [
          const _Mini(Brightness.dark),
          ClipRect(clipper: _LeftHalf(), child: const _Mini(Brightness.light)),
        ],
      ),
    };
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corners.row),
        side: BorderSide(
          color: selected ? context.tones.lilac.strong : Colors.transparent,
          width: 3,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Corners.small),
                child: SizedBox(height: 96, child: preview),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tiny page drawn in the real colors of [brightness].
class _Mini extends StatelessWidget {
  const _Mini(this.brightness);

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final scheme = buildTheme(brightness).colorScheme;
    final lilac = Tones.of(brightness).lilac;
    Widget bar(double width, {double height = 8, Color? color}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
    );
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, c) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            bar(c.maxWidth * 0.6),
            bar(c.maxWidth, height: 26, color: lilac.fill),
            bar(c.maxWidth),
            bar(c.maxWidth * 0.8),
          ],
        ),
      ),
    );
  }
}

class _LeftHalf extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) => Offset.zero & Size(size.width / 2, size.height);

  @override
  bool shouldReclip(_LeftHalf old) => false;
}

/// One row of mutually exclusive choices on a track.
class _Segments extends StatelessWidget {
  const _Segments({
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  final String? selected;
  final List<(String?, String)> options;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerHighest,
        shape: const StadiumBorder(),
      ),
      child: Row(
        children: [
          for (final (value, label) in options)
            Expanded(
              child: Semantics(
                selected: value == selected,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(value);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutQuart,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: ShapeDecoration(
                      color: value == selected
                          ? scheme.surface
                          : Colors.transparent,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: value == selected
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
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
