import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/ecourse_auth_repository.dart';
import '../../data/repositories/app_settings.dart';
import '../../data/repositories/ecourse_repository.dart';
import '../../data/services/app_update.dart';
import '../../data/services/reminders.dart';
import '../../data/services/response_cache.dart';
import '../../data/services/folder_stats.dart';
import '../../data/repositories/campus_cache.dart';
import '../../l10n/l10n.dart';
import '../core/theme.dart';
import '../home_widgets/home_widgets.dart';
import '../core/widgets.dart';
import '../core/segment_switch.dart';

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
            // Wallpaper colors exist on Android 12 and later only; elsewhere
            // the choice shows, unavailable, so the setting is known.
            SectionLabel(
              l10n.themeColors,
              detail: settings.wallpaperColor == null ? l10n.androidOnly : null,
            ),
            SegmentSwitch(
              labels: [l10n.themeDefault, l10n.themeWallpaper],
              selected: settings.seed != null ? 1 : 0,
              disabled: {if (settings.wallpaperColor == null) 1},
              onChanged: (i) => settings.setWallpaperColors(i == 1),
            ),
            SectionLabel(l10n.language),
            Builder(
              builder: (context) {
                final options = languageOptions(context);
                return SegmentSwitch(
                  labels: [for (final (_, label) in options) label],
                  selected: options.indexWhere(
                    (o) => o.$1 == settings.locale?.languageCode,
                  ),
                  onChanged: (i) => settings.setLocale(
                    options[i].$1 == null ? null : Locale(options[i].$1!),
                  ),
                );
              },
            ),
            const _Version(),
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
          padding: const EdgeInsets.fromLTRB(
            Space.s,
            Space.s,
            Space.s,
            Space.m,
          ),
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
    final theme = buildTheme(
      brightness,
      seed: context.watch<AppSettings>().seed,
    );
    final scheme = theme.colorScheme;
    final lilac = theme.extension<Tones>()!.lilac;
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
      padding: const EdgeInsets.all(Space.s),
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

  Future<void> _sendTest(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    if (!await Reminders.requestPermission()) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.notifyDenied)));
      return;
    }
    await Reminders.showTest(l10n.notifyTestShown);
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.m,
              Space.xs,
              Space.m,
              Space.m,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => _sendTest(context),
                icon: const Icon(Icons.notifications_active_outlined, size: 18),
                label: Text(l10n.notifyTest),
              ),
            ),
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

/// Design round-19 C: the version on its own card, checked against the
/// store on opening; with a newer one, its number, an update button and
/// its notes.
class _Version extends StatefulWidget {
  const _Version();

  @override
  State<_Version> createState() => _VersionState();
}

class _VersionState extends State<_Version> {
  // Apart, so the installed version shows when the store cannot be read.
  final _current = PackageInfo.fromPlatform();
  late Future<AppRelease?> _check = latestRelease();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final mute = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: scheme.onSurfaceVariant,
    );
    return FutureBuilder(
      future: _current,
      builder: (context, info) => FutureBuilder(
        future: _check,
        builder: (context, snap) {
          final current = info.data?.version;
          final latest = snap.data;
          final update =
              current != null &&
              latest != null &&
              isNewer(latest.version, current);
          final checking = snap.connectionState != ConnectionState.done;
          final (status, note) = checking
              ? (l10n.versionChecking, null)
              : snap.hasError || latest == null
              ? (l10n.versionCheckFailed, null)
              : update
              ? (l10n.versionUpdatable, l10n.versionCurrent(current))
              : (l10n.versionChecked, l10n.versionLatest);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionLabel(l10n.version, detail: latest?.source),
              Card(
                color: scheme.surfaceContainerLow,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(Space.l),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                (update ? latest.version : current) ?? '',
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                              if (note != null) ...[
                                const SizedBox(width: Space.s),
                                Text(note, style: mute.copyWith(fontSize: 15)),
                              ],
                            ],
                          ),
                          const SizedBox(height: Space.s),
                          Text(status, style: mute),
                          const SizedBox(height: Space.m),
                          if (update)
                            FilledButton(
                              onPressed: () => launchUrl(
                                latest.url,
                                mode: LaunchMode.externalApplication,
                              ),
                              child: Text(l10n.update),
                            )
                          else
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 40),
                              ),
                              onPressed: checking
                                  ? null
                                  : () => setState(
                                      () => _check = latestRelease(),
                                    ),
                              child: Text(l10n.checkUpdate),
                            ),
                        ],
                      ),
                    ),
                    if (update && latest.notes.isNotEmpty) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Space.l,
                          Space.m,
                          Space.l,
                          Space.l,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.whatsNewIn(latest.version),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: Space.xs),
                            for (final line in latest.notes)
                              Text(
                                line,
                                style: mute.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.6,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
