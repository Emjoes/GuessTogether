import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guesstogether/features/game/domain/game_models.dart';
import 'package:guesstogether/features/game/presentation/game_screen.dart';
import 'package:guesstogether/features/game/providers/game_providers.dart';

class _FakeGameController extends StateNotifier<GameState> {
  _FakeGameController()
      : super(
          GameState.initial().copyWith(
            players: const <Player>[
              Player(id: 'p1', name: 'You', score: 100),
              Player(id: 'p2', name: 'Bot', score: 50),
            ],
            remainingSeconds: 20,
          ),
        );

  Future<void> startMatch() async {}
}

void main() {
  testWidgets('GameScreen shows player row and timer', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameControllerProvider.overrideWith(
            (ref) => _FakeGameController(),
          ),
        ],
        child: const MaterialApp(
          home: GameScreen(),
        ),
      ),
    );

    expect(find.text('You'), findsOneWidget);
    expect(find.text('Bot'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
  });
}

