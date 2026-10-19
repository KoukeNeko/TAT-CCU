import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme and language the student picked; null language follows the
/// system, including the per-app language in iOS and Android settings.
/// [demoMode] fills alpha features with made-up data for showing them.
/// Stored on the device only.
class AppSettings extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _localeKey = 'locale';
  static const _demoKey = 'demo_mode';

  ThemeMode themeMode = ThemeMode.system;
  Locale? locale;
  bool demoMode = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode =
        ThemeMode.values.asNameMap()[prefs.getString(_themeKey)] ??
        ThemeMode.system;
    final code = prefs.getString(_localeKey);
    locale = code == null ? null : Locale(code);
    demoMode = prefs.getBool(_demoKey) ?? false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString(
      _themeKey,
      mode.name,
    );
  }

  Future<void> setLocale(Locale? value) async {
    locale = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, value.languageCode);
    }
  }

  Future<void> setDemoMode(bool on) async {
    demoMode = on;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setBool(_demoKey, on);
  }
}
