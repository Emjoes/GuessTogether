import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:guesstogether/features/home/presentation/home_screen.dart';
import 'package:guesstogether/features/game/presentation/game_screen.dart';
import 'package:guesstogether/features/game/providers/game_providers.dart';
import 'package:guesstogether/features/result/presentation/result_screen.dart';
import 'package:guesstogether/services/mock_match_host.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Happy path: create -> game -> results', (tester) async {
    // Make mock match fast for integration test.
    final fastHost = MockMatchHost(
      timing: const MockMatchTiming(
        beforeQuestion: Duration(milliseconds: 10),
        beforeAnswer: Duration(milliseconds: 10),
        afterMatch: Duration(milliseconds: 10),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          mockMatchHostProvider.overrideWithValue(fastHost),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Create Room'));
    await tester.pumpAndSettle();

    // Create room navigates to Game.
    await tester.tap(find.text('Create Room'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);

    await tester.tap(find.text('Start scripted match'));
    await tester.pump(const Duration(milliseconds: 50));

    // Wait for match end navigation.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(ResultScreen), findsOneWidget);
  });
}

