import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../domain/models/course.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// The course's name in the interface language: Chinese for zh, English
  /// otherwise.
  String courseName(Course c) =>
      c.name(chinese: Localizations.localeOf(this).languageCode == 'zh');

  /// [fullName] as eCourse2 joins it, in the interface language, for the
  /// lists that carry only the name.
  String courseNameOf(String fullName) => courseNameIn(
    fullName,
    chinese: Localizations.localeOf(this).languageCode == 'zh',
  );
}

/// Strings outside the widget tree (notifications, home screen widgets):
/// the language chosen in settings, else the device's.
AppLocalizations l10nFor(Locale? chosen) => lookupAppLocalizations(
  basicLocaleListResolution([
    ?chosen,
    ...PlatformDispatcher.instance.locales,
  ], AppLocalizations.supportedLocales),
);
