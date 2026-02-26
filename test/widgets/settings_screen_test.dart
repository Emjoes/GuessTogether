import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
import 'package:guesstogether/core/l10n/app_locale.dart';
import 'package:guesstogether/core/theme/app_theme.dart';
import 'package:guesstogether/features/settings/presentation/settings_screen.dart';
import '../test_app.dart';

void main() {
  testWidgets('SettingsScreen shows all theme options', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: _SettingsApp(),
      ),
    );

    expect(find.text(AppStrings.settingsTheme), findsOneWidget);
    expect(find.text(AppStrings.settingsThemeSystem), findsNWidgets(2));
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

  testWidgets('SettingsScreen updates theme mode on tap', (tester) async {
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

    expect(container.read(themeModeProvider), ThemeMode.system);

    await tester.tap(find.text(AppStrings.settingsThemeLight));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.light);

    await tester.tap(find.text(AppStrings.settingsThemeSystem).first);
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  testWidgets('SettingsScreen updates language on tap', (tester) async {
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

    expect(container.read(appLanguageProvider), AppLanguage.system);

    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();

    expect(container.read(appLanguageProvider), AppLanguage.russian);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(container.read(appLanguageProvider), AppLanguage.english);
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
