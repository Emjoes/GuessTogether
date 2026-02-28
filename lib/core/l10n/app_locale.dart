import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage {
  english,
  russian,
}

extension AppLanguageLocale on AppLanguage {
  Locale get locale {
    switch (this) {
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.russian:
        return const Locale('ru');
    }
  }
}

AppLanguage _defaultAppLanguageFromSystem() {
  final String code = WidgetsBinding
      .instance.platformDispatcher.locale.languageCode
      .toLowerCase();
  switch (code) {
    case 'ru':
      return AppLanguage.russian;
    case 'en':
      return AppLanguage.english;
    default:
      // Fallback for unsupported or unknown system locales.
      return AppLanguage.english;
  }
}

final appLanguageProvider = StateProvider<AppLanguage>(
  (ref) => _defaultAppLanguageFromSystem(),
);
