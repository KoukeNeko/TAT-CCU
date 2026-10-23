import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme and language the student picked; null language follows the
/// system, including the per-app language in iOS and Android settings.
/// Stored on the device only.
class AppSettings extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _localeKey = 'locale';
  static const _dueKey = 'notify_due';
  static const _classKey = 'notify_class';
  static const _newsKey = 'notify_news';
  static const _weekKey = 'timetable_week';
  static const _colorKey = 'wallpaper_colors';

  ThemeMode themeMode = ThemeMode.system;

  /// The 主題 picked: the Android wallpaper's colors instead of lilac.
  bool wallpaperColors = false;

  /// The wallpaper's main color, read at launch; null where the system has
  /// none (before Android 12, and on iOS, macOS and Windows).
  Color? wallpaperColor;

  /// The color the theme is built around, when not the app's own.
  Color? get seed => wallpaperColors ? wallpaperColor : null;
  Locale? locale;

  /// Local reminders before deadlines and classes, and the background
  /// check for new eCourse2 notices and mail. Off until the student asks.
  bool notifyDue = false, notifyClass = false, notifyNews = false;

  /// The phone timetable shows the whole week instead of one day.
  bool timetableWeek = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode =
        ThemeMode.values.asNameMap()[prefs.getString(_themeKey)] ??
        ThemeMode.system;
    final code = prefs.getString(_localeKey);
    locale = code == null ? null : Locale(code);
    notifyDue = prefs.getBool(_dueKey) ?? false;
    notifyClass = prefs.getBool(_classKey) ?? false;
    notifyNews = prefs.getBool(_newsKey) ?? false;
    timetableWeek = prefs.getBool(_weekKey) ?? false;
    wallpaperColors = prefs.getBool(_colorKey) ?? false;
    // The plugin has no iOS side; Android below 12 answers null.
    if (Platform.isAndroid) {
      final palette = await DynamicColorPlugin.getCorePalette();
      wallpaperColor = palette == null ? null : Color(palette.primary.get(40));
    }
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

  Future<void> setWallpaperColors(bool on) async {
    wallpaperColors = on;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setBool(_colorKey, on);
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

  Future<void> setTimetableWeek(bool week) async {
    timetableWeek = week;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setBool(_weekKey, week);
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
