import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
import 'package:guesstogether/core/theme/app_theme.dart';
import 'package:guesstogether/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('SettingsScreen shows all theme options', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    expect(find.text(AppStrings.settingsTheme), findsOneWidget);
    expect(find.text(AppStrings.settingsThemeSystem), findsOneWidget);
    expect(find.text(AppStrings.settingsThemeLight), findsOneWidget);
    expect(find.text(AppStrings.settingsThemeDark), findsOneWidget);
  });

  testWidgets('SettingsScreen updates theme mode on tap', (tester) async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    expect(container.read(themeModeProvider), ThemeMode.system);

    await tester.tap(find.text(AppStrings.settingsThemeLight));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.light);

    await tester.tap(find.text(AppStrings.settingsThemeSystem));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.system);
  });
}
