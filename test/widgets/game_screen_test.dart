import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/features/game/domain/game_models.dart';
import 'package:guesstogether/features/game/presentation/game_screen.dart';
import 'package:guesstogether/features/game/providers/game_providers.dart';
import '../test_app.dart';

class _FakeGameController extends GameController {
  _FakeGameController() : super() {
    state = GameState.initial().copyWith(
      players: const <Player>[
        Player(id: 'p1', name: 'You', score: 100),
        Player(id: 'p2', name: 'Bot', score: 50),
      ],
      phase: GamePhase.boardSelection,
      phaseSecondsLeft: 20,
      phaseSecondsTotal: 20,
    );
  }

  @override
  Future<void> startMatch() async {}
}

void main() {
  testWidgets('GameScreen shows player row', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameControllerProvider.overrideWith(
            (ref) => _FakeGameController(),
          ),
        ],
        child: buildTestMaterialApp(
          home: const GameScreen(),
          locale: const Locale('en'),
        ),
      ),
    );

    expect(find.text('You'), findsOneWidget);
    expect(find.text('Bot'), findsOneWidget);
  });

  testWidgets('Tapping player tile does not open manual score dialog',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameControllerProvider.overrideWith(
            (ref) => _FakeGameController(),
          ),
        ],
        child: buildTestMaterialApp(
          home: const GameScreen(),
          locale: const Locale('en'),
        ),
      ),
    );

    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();

    expect(find.text('Set score: You'), findsNothing);
  });

  testWidgets('Back action shows leave confirmation with reconnect hint',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameControllerProvider.overrideWith(
            (ref) => _FakeGameController(),
          ),
        ],
        child: buildTestMaterialApp(
          home: const GameScreen(),
          locale: const Locale('en'),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Leave match?'), findsOneWidget);
    expect(
      find.text('You can reconnect to this match later.'),
      findsOneWidget,
    );
  });

  testWidgets('Escape action shows leave confirmation with reconnect hint',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameControllerProvider.overrideWith(
            (ref) => _FakeGameController(),
          ),
        ],
        child: buildTestMaterialApp(
          home: const GameScreen(),
          locale: const Locale('en'),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Leave match?'), findsOneWidget);
    expect(
      find.text('You can reconnect to this match later.'),
      findsOneWidget,
    );
  });
}
