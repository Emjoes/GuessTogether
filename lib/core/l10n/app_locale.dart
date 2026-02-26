import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage {
  system,
  english,
  russian,
}

extension AppLanguageLocale on AppLanguage {
  Locale? get locale {
    switch (this) {
      case AppLanguage.system:
        return null;
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.russian:
        return const Locale('ru');
    }
  }
}

final appLanguageProvider = StateProvider<AppLanguage>(
  (ref) => AppLanguage.system,
);
