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
  static const _dueKey = 'notify_due';
  static const _classKey = 'notify_class';
  static const _newsKey = 'notify_news';

  ThemeMode themeMode = ThemeMode.system;
  Locale? locale;
  bool demoMode = false;

  /// Local reminders before deadlines and classes, and the background
  /// check for new eCourse2 notices and mail. Off until the student asks.
  bool notifyDue = false, notifyClass = false, notifyNews = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode =
        ThemeMode.values.asNameMap()[prefs.getString(_themeKey)] ??
        ThemeMode.system;
    final code = prefs.getString(_localeKey);
    locale = code == null ? null : Locale(code);
    demoMode = prefs.getBool(_demoKey) ?? false;
    notifyDue = prefs.getBool(_dueKey) ?? false;
    notifyClass = prefs.getBool(_classKey) ?? false;
    notifyNews = prefs.getBool(_newsKey) ?? false;
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

  Future<void> setNotify({bool? due, bool? classes, bool? news}) async {
    notifyDue = due ?? notifyDue;
    notifyClass = classes ?? notifyClass;
    notifyNews = news ?? notifyNews;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await (
      prefs.setBool(_dueKey, notifyDue),
      prefs.setBool(_classKey, notifyClass),
      prefs.setBool(_newsKey, notifyNews),
    ).wait;
  }
}
