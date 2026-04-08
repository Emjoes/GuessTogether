import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:guesstogether/app_router.dart';
import 'package:guesstogether/core/debug/loading_debug_gate.dart';
import 'package:guesstogether/core/l10n/app_locale.dart';
import 'package:guesstogether/core/l10n/generated/app_localizations.dart';
import 'package:guesstogether/core/theme/app_theme.dart';
import 'package:guesstogether/features/session/app_session_controller.dart';
import 'package:guesstogether/widgets/mobile_shell.dart';

Future<void> _preloadCriticalFonts() async {
  try {
    final FontLoader materialIconsLoader = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIconsLoader.load();
  } catch (_) {
    // Flutter already knows how to load Material icons from the asset
    // manifest. This preload is best-effort to avoid missing glyphs on web
    // when multiple windows bootstrap at the same time.
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await _preloadCriticalFonts();

  LicenseRegistry.addLicense(() async* {
    final String soraLicense = await rootBundle.loadString(
      'assets/fonts/google_fonts/Sora-OFL.txt',
    );
    final String manropeLicense = await rootBundle.loadString(
      'assets/fonts/google_fonts/Manrope-OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(
      const <String>['google_fonts'],
      '$soraLicense\n\n$manropeLicense',
    );
  });

  // Lock orientation to portrait only.
  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[DeviceOrientation.portraitUp],
  );

  runApp(const ProviderScope(child: GuessTogetherApp()));
}

class GuessTogetherApp extends ConsumerWidget {
  const GuessTogetherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final appLanguage = ref.watch(appLanguageProvider);

    return MaterialApp.router(
      title: 'Guess Together',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      locale: appLanguage.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
      builder: (context, child) {
        return LoadingDebugOverlay(
          child: MobileShell(child: child ?? const SizedBox.shrink()),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
