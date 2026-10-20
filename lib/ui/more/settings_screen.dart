import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_auth_repository.dart';
import '../../data/repositories/app_settings.dart';
import '../../data/repositories/ecourse_repository.dart';
import '../../data/services/reminders.dart';
import '../../data/services/response_cache.dart';
import '../../data/services/folder_stats.dart';
import '../../data/repositories/campus_cache.dart';
import '../../l10n/l10n.dart';
import '../core/theme.dart';
import '../home_widgets/home_widgets.dart';
import '../core/widgets.dart';

/// The app's languages by code; null follows the system. Each language is
/// named in itself so it can be found from any of the others.
List<(String?, String)> languageOptions(BuildContext context) => [
  (null, context.l10n.followSystem),
  ('zh', '繁中'),
  ('en', 'English'),
  ('ja', '日本語'),
];

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
              options: languageOptions(context),
              onSelected: (code) =>
                  settings.setLocale(code == null ? null : Locale(code)),
            ),
            SectionLabel(l10n.notifications),
            const _Notifications(),
            SectionLabel(l10n.savedData),
            const _SavedData(),
            SectionLabel(l10n.aboutApp),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                title: Text(
                  l10n.demoMode,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(l10n.demoModeDetail),
                value: context.watch<EcourseAuthRepository>().isDemo,
                onChanged: context.read<EcourseAuthRepository>().setDemo,
              ),
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

/// Local reminders and the background check (Reminders); each asks for the
/// system permission the first time it is turned on.
class _Notifications extends StatelessWidget {
  const _Notifications();

  Future<void> _set(
    BuildContext context, {
    bool? due,
    bool? classes,
    bool? news,
  }) async {
    final settings = context.read<AppSettings>();
    final repo = context.read<EcourseRepository>();
    final demo = context.read<EcourseAuthRepository>().isDemo;
    final messenger = ScaffoldMessenger.of(context);
    final denied = context.l10n.notifyDenied;
    if ((due ?? classes ?? news)! && !await Reminders.requestPermission()) {
      messenger.showSnackBar(SnackBar(content: Text(denied)));
      return;
    }
    await settings.setNotify(due: due, classes: classes, news: news);
    // The demo account's made-up deadlines never become reminders; they
    // are scheduled for the real account when it is back.
    if (demo) return;
    await Reminders.updateBackground(
      settings,
      widgets: await HomeWidgets.installed(),
    );
    if (due != null || classes != null) {
      try {
        await Reminders.sync(repo, settings);
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<AppSettings>();
    Widget tile(
      String title,
      String detail,
      bool value,
      ValueChanged<bool> onChanged,
    ) => SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(detail),
      value: value,
      onChanged: onChanged,
    );
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          tile(
            l10n.notifyDue,
            l10n.notifyDueDetail,
            settings.notifyDue,
            (on) => _set(context, due: on),
          ),
          tile(
            l10n.notifyClass,
            l10n.notifyClassDetail,
            settings.notifyClass,
            (on) => _set(context, classes: on),
          ),
          tile(
            l10n.notifyNews,
            l10n.notifyNewsDetail,
            settings.notifyNews,
            (on) => _set(context, news: on),
          ),
        ],
      ),
    );
  }
}

/// How much each cache holds on the device, read once when the page opens;
/// either row opens the details.
class _SavedData extends StatefulWidget {
  const _SavedData();

  @override
  State<_SavedData> createState() => _SavedDataState();
}

class _SavedDataState extends State<_SavedData> {
  final _stats = (
    ResponseCache.files().then(summarize),
    CampusCache.files().then(summarize),
  ).wait;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String describe(FolderStats s) => switch (s.latest) {
      final latest? when s.files > 0 => [
        l10n.savedItems(s.files),
        fileSize(s.bytes),
        l10n.updatedAt(monthDayTime(latest)),
      ].join('・'),
      _ => l10n.noData,
    };
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder(
        future: _stats,
        builder: (context, snapshot) {
          final stats = snapshot.data;
          return Column(
            children: [
              for (final (title, s) in [
                ('eCourse2', stats?.$1),
                (l10n.campusSystems, stats?.$2),
              ])
                ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(s == null ? '' : describe(s)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/more/settings/saved'),
                ),
            ],
          );
        },
      ),
    );
  }
}
