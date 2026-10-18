import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'data/repositories/ecourse_auth_repository.dart';
import 'data/repositories/ecourse_repository.dart';
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
  await auth.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
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
    return MaterialApp.router(
      title: 'TAT CCU',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      routerConfig: router,
    );
  }
}
