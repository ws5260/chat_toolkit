import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// Language the site is shown in. The header's language switch changes it.
final ValueNotifier<Locale> siteLocale = ValueNotifier(const Locale('en'));

/// Names shown for each language in the switch.
const Map<String, String> siteLanguageNames = {
  'en': 'English',
  'ko': '한국어',
  'ja': '日本語',
  'zh': '中文',
};

/// Localized title of a demo room.
String roomTitle(AppLocalizations l, String id) => switch (id) {
      'short' => l.roomShortTitle,
      'normal' => l.roomNormalTitle,
      'long' => l.roomLongTitle,
      'images' => l.roomImagesTitle,
      'slow' => l.roomSlowTitle,
      _ => id,
    };

/// Localized description of a demo room.
String roomDescription(AppLocalizations l, String id) => switch (id) {
      'short' => l.roomShortDesc,
      'normal' => l.roomNormalDesc,
      'long' => l.roomLongDesc,
      'images' => l.roomImagesDesc,
      'slow' => l.roomSlowDesc,
      _ => '',
    };
