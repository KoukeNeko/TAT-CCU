import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart' as clk;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'data/repositories/app_settings.dart';
import 'data/repositories/ecourse_auth_repository.dart';
import 'data/repositories/ecourse_repository.dart';
import 'data/repositories/more_tiles_prefs.dart';
import 'data/services/campus_cookies.dart';
import 'data/services/ecourse_maintenance.dart';
import 'data/services/reminders.dart';
import 'data/services/school_calendar.dart';
import 'l10n/l10n.dart';
import 'routing/router.dart';
import 'ui/home_widgets/home_widgets.dart';
import 'ui/core/command_palette.dart';
import 'ui/core/desktop_mode.dart';
import 'ui/core/theme.dart';
import 'ui/core/widgets.dart';
import 'ui/core/windows_caption.dart';
import 'ui/notifications/notifications_screen.dart';
import 'data/repositories/dorm_repair_data.dart';
import 'data/repositories/parttime_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge to edge: content draws behind transparent status and navigation
  // bars; screens pad themselves with the media insets.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  final auth = EcourseAuthRepository();
  final settings = AppSettings();
  // Alpha features show their sample data to the demo account.
  void showDemo() {
    HoursStore.instance.demo = auth.isDemo;
    DormRepairStore.instance.demo = auth.isDemo;
  }

  auth.addListener(showDemo);
  // Signing in or out, or into the demo, changes what the widgets show.
  auth.addListener(() => _updateWidgets(auth, settings));
  // Signing out cancels that account's reminders at once.
  auth.addListener(() {
    if (!auth.isSignedIn) unawaited(_remind(auth, settings));
  });
  // A step that fails must not keep the launch screen up: the app starts
  // without it, and the sign-in is read again once the app comes back.
  var authLoaded = true;
  try {
    await (
      settings.load(),
      auth.load(),
      CampusCookies.restore(),
      Reminders.init(),
      loadSchoolCalendar(),
    ).wait;
  } on ParallelWaitError<
    (void, void, void, void, void),
    (AsyncError?, AsyncError?, AsyncError?, AsyncError?, AsyncError?)
  > catch (e) {
    authLoaded = e.errors.$2 == null;
    for (final error in [
      e.errors.$1,
      e.errors.$2,
      e.errors.$3,
      e.errors.$4,
      e.errors.$5,
    ]) {
      if (error == null) continue;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error.error,
          stack: error.stackTrace,
          library: 'startup',
        ),
      );
    }
  }
  // iOS may end a backgrounded app without notice, so save on the way out.
  AppLifecycleListener(
    onHide: CampusCookies.save,
    onResume: () {
      if (!authLoaded) {
        authLoaded = true;
        // Still unreadable: tried again on the next return.
        unawaited(auth.load().catchError((Object _) => authLoaded = false));
      }
      _remind(auth, settings);
      _prefetch(auth);
      _updateWidgets(auth, settings);
      EcourseMaintenance.instance.check();
    },
  );
  showDemo();
  if (Platform.isIOS) {
    isPhoneDevice =
        await const MethodChannel('tatccu/device')
            .invokeMethod<bool>('isPhone') ??
        false;
  }
  if (Platform.isIOS || Platform.isAndroid) {
    await Workmanager().initialize(backgroundTask);
  }
  if (Platform.isWindows) await hideWindowsTitleBar();
  await watchDesktopMode();
  unawaited(_remind(auth, settings));
  unawaited(_prefetch(auth));
  unawaited(_updateWidgets(auth, settings));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => MoreTilesPrefs()..load()),
        ChangeNotifierProvider.value(value: settings),
        ProxyProvider<EcourseAuthRepository, EcourseRepository>(
          update: (_, auth, _) => EcourseRepository(auth.client()),
        ),
      ],
      child: const TatCcuApp(),
    ),
  );
}

class TatCcuApp extends StatefulWidget {
  const TatCcuApp({super.key});

  @override
  State<TatCcuApp> createState() => _TatCcuAppState();
}

/// One router per account: tabs stay alive while the app runs, so
/// switching between the real and the demo account starts them afresh
/// instead of leaving them on the other account's data.
class _TatCcuAppState extends State<TatCcuApp> {
  late final _auth = context.read<EcourseAuthRepository>();
  late bool _demo = _auth.isDemo;
  late GoRouter _router = buildRouter(_auth);

  @override
  void initState() {
    super.initState();
    Reminders.tapped.addListener(_openTapped);
    // A notification that launched the app waits for the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openTapped());
  }

  @override
  void dispose() {
    Reminders.tapped.removeListener(_openTapped);
    _router.dispose();
    super.dispose();
  }

  /// Opens the page of the notification the student tapped.
  void _openTapped() {
    final payload = Reminders.tapped.value;
    final navigator = _router.routerDelegate.navigatorKey.currentState;
    if (payload == null || navigator == null) return;
    Reminders.tapped.value = null;
    // Starts from the tab the page belongs to, not on top of whatever is
    // open: a page already in the stack would otherwise stay in front.
    navigator.popUntil((route) => route.isFirst);
    if (payload.startsWith('mail:')) {
      _router.go('/messages');
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => MailScreen(id: int.parse(payload.substring(5))),
        ),
      );
    } else if (payload.startsWith('/')) {
      _router.go(payload);
    } else {
      _router.go('/messages');
      // After the tab has switched, so the page is pushed onto it.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => openEcourseLink(navigator.context, payload),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final demo = context.select<EcourseAuthRepository, bool>((a) => a.isDemo);
    if (demo != _demo) {
      final old = _router;
      _demo = demo;
      _router = buildRouter(_auth);
      // Still mounted this frame; let it go after.
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    return MaterialApp.router(
      key: ValueKey(demo),
      title: 'TAT CCU',
      theme: buildTheme(Brightness.light, seed: settings.seed),
      darkTheme: buildTheme(Brightness.dark, seed: settings.seed),
      themeMode: settings.themeMode,
      locale: _traditional(settings.locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: [
        for (final l in AppLocalizations.supportedLocales) _traditional(l)!,
      ],
      builder: (context, child) {
        // macOS and Windows draw the content under the title bar, which
        // takes the clicks there; pages treat it like a status bar.
        final titleBar = _titleBarHeight;
        if (titleBar != null) {
          final media = MediaQuery.of(context);
          child = MediaQuery(
            data: media.copyWith(
              padding: media.padding.copyWith(top: titleBar),
              viewPadding: media.viewPadding.copyWith(top: titleBar),
            ),
            child: child!,
          );
        }
        if (Platform.isIOS) {
          final media = MediaQuery.of(context);
          final fold = duoFold(media);
          if (fold.isNotEmpty) {
            child = MediaQuery(
              data: media.copyWith(displayFeatures: fold),
              child: child!,
            );
          }
        }
        // Japanese gets LINE Seed JP so kanji take Japanese shapes; the
        // desktop UI its denser bars and the ⌘K palette.
        final ja = Localizations.localeOf(context).languageCode == 'ja';
        child = ValueListenableBuilder(
          valueListenable: desktopMode,
          child: child,
          builder: (context, desktop, child) {
            var theme = Theme.of(context);
            if (ja) {
              theme = buildTheme(
                theme.brightness,
                fontFamily: fontJp,
                seed: settings.seed,
              );
            }
            return DesktopScope(
              desktop: desktop,
              child: Theme(
                data: desktop ? desktopTheme(theme) : theme,
                child: desktop
                    ? CommandPaletteHotkey(
                        navigator: _router.routerDelegate.navigatorKey,
                        child: child!,
                      )
                    : child!,
              ),
            );
          },
        );
        // A tap outside a text field ends typing on phones too; Flutter only
        // does so for mice. Fields share one tap group, so moving between
        // them keeps the keyboard up.
        child = Actions(
          actions: {
            EditableTextTapOutsideIntent:
                CallbackAction<EditableTextTapOutsideIntent>(
                  onInvoke: (intent) => intent.focusNode.unfocus(),
                ),
          },
          child: child,
        );
        return Platform.isWindows ? WindowsCaption(child: child) : child;
      },
      routerConfig: _router,
    );
  }
}

/// Height of the macOS unified toolbar title bar (MainFlutterWindow).
const _macTitleBar = 52.0;

/// Height of the title bar the content draws under, if the window has one.
final double? _titleBarHeight = Platform.isMacOS
    ? _macTitleBar
    : Platform.isWindows
    ? windowsCaptionHeight
    : null;

/// Reschedules reminders from the latest deadlines and timetable, so a
/// changed due date is not announced at the old time.
Future<void> _remind(EcourseAuthRepository auth, AppSettings settings) async {
  if (auth.isDemo) return;
  try {
    // A signed-out account's classes and deadlines are not announced.
    if (!auth.isSignedIn) return await Reminders.cancelScheduled();
    await Reminders.updateBackground(
      settings,
      widgets: await HomeWidgets.installed(),
    );
    await Reminders.sync(EcourseRepository(auth.client()), settings);
  } catch (e) {
    // Offline or signed out: the reminders already scheduled stay.
    debugPrint('reminders: $e');
  }
}

DateTime? _prefetchedAt;

/// At launch, then on coming back after half an hour: what was saved this
/// recently is still current enough.
Future<void> _prefetch(EcourseAuthRepository auth) async {
  final last = _prefetchedAt;
  if (!auth.isSignedIn ||
      auth.isDemo ||
      last != null && clk.clock.now().difference(last).inMinutes < 30) {
    return;
  }
  _prefetchedAt = clk.clock.now();
  try {
    await EcourseRepository(auth.client()).prefetch();
  } catch (e) {
    // Offline or a stalled request: the screens load what they need.
    debugPrint('prefetch: $e');
  }
}

Future<void> _updateWidgets(
  EcourseAuthRepository auth,
  AppSettings settings,
) async {
  try {
    await HomeWidgets.sync(auth, settings);
  } catch (e) {
    // Offline: the widgets keep the frames written last time.
    debugPrint('widgets: $e');
  }
}

/// Entry point of the background task, in its own isolate.
@pragma('vm:entry-point')
void backgroundTask() {
  Workmanager().executeTask((task, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    final settings = AppSettings();
    final auth = EcourseAuthRepository();
    await (
      settings.load(),
      auth.load(),
      Reminders.init(),
      loadSchoolCalendar(),
    ).wait;
    await _updateWidgets(auth, settings);
    if (!auth.isSignedIn || auth.isDemo) return true;
    final repo = EcourseRepository(auth.client());
    if (settings.notifyDue || settings.notifyClass) {
      await Reminders.sync(repo, settings);
    }
    if (settings.notifyNews) await Reminders.checkNews(repo, settings);
    return true;
  });
}

/// Plain `zh` would give Flutter's own pages (licenses, date pickers)
/// Simplified Chinese; the app's Chinese is Taiwan's Traditional.
Locale? _traditional(Locale? l) => l?.languageCode == 'zh'
    ? const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'TW',
      )
    : l;
