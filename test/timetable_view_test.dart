import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tat_ccu/data/repositories/app_settings.dart';
import 'package:tat_ccu/data/repositories/ecourse_auth_repository.dart';
import 'package:tat_ccu/data/repositories/ecourse_repository.dart';
import 'package:tat_ccu/data/services/demo_data.dart';
import 'package:tat_ccu/l10n/l10n.dart';
import 'package:tat_ccu/ui/core/theme.dart';
import 'package:tat_ccu/ui/timetable/timetable_screen.dart';

void main() {
  testWidgets('the day picked before the week view is shown after it', (
    t,
  ) => withClock(Clock.fixed(DateTime(2026, 11, 3, 9, 30)), () async {
    t.view.physicalSize = const Size(390, 844) * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await t.runAsync(settings.load);
    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => EcourseAuthRepository()),
          ChangeNotifierProvider.value(value: settings),
          Provider(create: (_) => EcourseRepository(DemoMoodleClient())),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.dark),
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TimetableScreen(),
        ),
      ),
    );
    await t.pumpAndSettle();

    // Monday's only class, on a Tuesday.
    await t.tap(find.text('一'));
    await t.pumpAndSettle();
    expect(find.textContaining('計算機專題'), findsWidgets);

    await t.tap(find.text('週'));
    await t.pumpAndSettle();
    await t.tap(find.text('日'));
    await t.pumpAndSettle();
    expect(find.textContaining('計算機專題'), findsWidgets);
  }));
}
