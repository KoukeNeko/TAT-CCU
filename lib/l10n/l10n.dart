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
}
