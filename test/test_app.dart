import 'package:flutter/material.dart';

import 'package:guesstogether/core/l10n/generated/app_localizations.dart';

MaterialApp buildTestMaterialApp({
  required Widget home,
  Locale? locale,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

MaterialApp buildTestMaterialAppRouter({
  required RouterConfig<Object> routerConfig,
  Locale? locale,
}) {
  return MaterialApp.router(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: routerConfig,
  );
}
