import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
import 'package:guesstogether/core/l10n/app_locale.dart';
import 'package:guesstogether/features/auth/presentation/auth_screen.dart';
import 'package:guesstogether/features/settings/presentation/settings_screen.dart';
import 'package:guesstogether/features/session/app_session_controller.dart';
import '../test_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('SettingsScreen shows all theme options', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: _SettingsApp(),
      ),
    );

    expect(find.text(AppStrings.settingsTheme), findsOneWidget);
    expect(find.text(AppStrings.settingsThemeSystem), findsNothing);
    expect(find.text('System'), findsNothing);
    expect(find.text(AppStrings.settingsThemeLight), findsOneWidget);
    expect(find.text(AppStrings.settingsThemeDark), findsOneWidget);
    expect(find.text('GB'), findsNothing);
    expect(find.text('RU'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.runtimeType.toString() == '_UkFlag' ||
            widget.runtimeType.toString() == '_RuFlag',
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('SettingsScreen shows logout account block', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: _SettingsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
    expect(
      find.text('The current session will be cleared on this device.'),
      findsNothing,
    );
  });

  testWidgets('SettingsScreen updates theme mode on tap', (tester) async {
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    addTearDown(
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
    );

    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: buildTestMaterialApp(
          home: const SettingsScreen(),
          locale: const Locale('en'),
        ),
      ),
    );

    expect(container.read(themeModeProvider), ThemeMode.dark);

    await tester.tap(find.text(AppStrings.settingsThemeLight));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.light);

    await tester.tap(find.text(AppStrings.settingsThemeDark));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('SettingsScreen updates language on tap', (tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('ru');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: buildTestMaterialApp(
          home: const SettingsScreen(),
          locale: const Locale('en'),
        ),
      ),
    );

    expect(container.read(appLanguageProvider), AppLanguage.russian);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(container.read(appLanguageProvider), AppLanguage.english);

    final Finder russianFlag = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_RuFlag',
    );
    await tester.tap(
      find.ancestor(of: russianFlag, matching: find.byType(InkWell)),
    );
    await tester.pumpAndSettle();

    expect(container.read(appLanguageProvider), AppLanguage.russian);
  });

  testWidgets('Unsupported system locale falls back to English',
      (tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('es');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: buildTestMaterialApp(
          home: const SettingsScreen(),
          locale: const Locale('en'),
        ),
      ),
    );

    expect(container.read(appLanguageProvider), AppLanguage.english);
  });

  testWidgets('Escape triggers back action when app bar shows back arrow',
      (tester) async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: buildTestMaterialApp(
          locale: const Locale('en'),
          home: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: const Text('Open settings'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text(AppStrings.settingsTitle), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Open settings'), findsOneWidget);
    expect(find.text(AppStrings.settingsTitle), findsNothing);
  });

  testWidgets('SettingsScreen logout navigates to auth', (tester) async {
    final GoRouter router = GoRouter(
      initialLocation: SettingsScreen.routePath,
      routes: <RouteBase>[
        GoRoute(
          path: SettingsScreen.routePath,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: AuthScreen.routePath,
          builder: (context, state) => const AuthScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: buildTestMaterialAppRouter(
          routerConfig: router,
          locale: const Locale('en'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsOneWidget);
  });
}

class _SettingsApp extends StatelessWidget {
  const _SettingsApp();

  @override
  Widget build(BuildContext context) {
    return buildTestMaterialApp(
      home: const SettingsScreen(),
      locale: const Locale('en'),
    );
  }
}
