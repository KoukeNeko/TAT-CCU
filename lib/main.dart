import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'data/repositories/app_settings.dart';
import 'data/repositories/ecourse_auth_repository.dart';
import 'data/repositories/ecourse_repository.dart';
import 'data/repositories/portal_prefs.dart';
import 'data/services/campus_cookies.dart';
import 'l10n/l10n.dart';
import 'routing/router.dart';
import 'ui/core/theme.dart';

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
  await (auth.load(), CampusCookies.restore()).wait;
  // iOS may end a backgrounded app without notice, so save on the way out.
  AppLifecycleListener(onHide: CampusCookies.save);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => PortalPrefs()..load()),
        ChangeNotifierProvider(create: (_) => AppSettings()..load()),
        ProxyProvider<EcourseAuthRepository, EcourseRepository>(
          update: (_, auth, _) => EcourseRepository(auth.client()),
        ),
      ],
      child: TatCcuApp(router: buildRouter(auth)),
    ),
  );
}

class TatCcuApp extends StatelessWidget {
  const TatCcuApp({super.key, required this.router});

  final RouterConfig<Object> router;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    return MaterialApp.router(
      title: 'TAT CCU',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Japanese gets LINE Seed JP so kanji take Japanese shapes.
      builder: (context, child) =>
          Localizations.localeOf(context).languageCode == 'ja'
          ? Theme(
              data: buildTheme(
                Theme.of(context).brightness,
                fontFamily: fontJp,
              ),
              child: child!,
            )
          : child!,
      routerConfig: router,
    );
  }
}
