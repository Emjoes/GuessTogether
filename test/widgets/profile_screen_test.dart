import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
import 'package:guesstogether/features/profile/presentation/profile_screen.dart';
import '../test_app.dart';

void main() {
  testWidgets('ProfileScreen shows tabbed profile sections',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: _ProfileApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byTooltip(AppStrings.profileTabStats), findsOneWidget);
    expect(find.byTooltip(AppStrings.profileTabLeaderboards), findsOneWidget);
    expect(find.byTooltip(AppStrings.profileTabAchievements), findsOneWidget);
    expect(find.text(AppStrings.profileStatsLabel), findsOneWidget);
    expect(find.text(AppStrings.profileRecentGames), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.profileTabLeaderboards));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.profileLeaderboards), findsOneWidget);
    expect(find.text('global Player 1'), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.profileTabAchievements));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.profileAchievements), findsWidgets);
  });
}

class _ProfileApp extends StatelessWidget {
  const _ProfileApp();

  @override
  Widget build(BuildContext context) {
    return buildTestMaterialApp(
      home: const ProfileScreen(),
      locale: const Locale('en'),
    );
  }
}
