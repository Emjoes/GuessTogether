import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/features/game/domain/game_models.dart';

import '../../bin/server.dart';

GameState _buildFinishedMatch() {
  return GameState.initial(
    players: const <Player>[
      Player(id: 'p1', name: 'Alice', score: 300),
      Player(id: 'p2', name: 'Bob', score: 100),
    ],
  ).copyWith(
    phase: GamePhase.finished,
    isMatchEnded: true,
    winnerId: 'p1',
    phaseSecondsLeft: 0,
    phaseSecondsTotal: 0,
  );
}

void main() {
  test('profile updates apply only for natural match finish', () {
    final GameState previousState = GameState.initial(
      players: const <Player>[
        Player(id: 'p1', name: 'Alice', score: 0),
        Player(id: 'p2', name: 'Bob', score: 0),
      ],
    );
    final StoredMatchProgress matchProgress = StoredMatchProgress();

    final bool shouldApply = shouldApplyMatchProfileUpdates(
      previousState: previousState,
      nextState: _buildFinishedMatch(),
      matchProgress: matchProgress,
    );

    expect(shouldApply, isTrue);
  });

  test('profile updates do not apply after abandonment finish', () {
    final GameState previousState = GameState.initial(
      players: const <Player>[
        Player(id: 'p1', name: 'Alice', score: 0),
        Player(id: 'p2', name: 'Bob', score: 0),
      ],
    );
    final StoredMatchProgress matchProgress = StoredMatchProgress(
      endedByAbandonment: true,
    );

    final bool shouldApply = shouldApplyMatchProfileUpdates(
      previousState: previousState,
      nextState: _buildFinishedMatch(),
      matchProgress: matchProgress,
    );

    expect(shouldApply, isFalse);
  });

  test('profile updates do not apply twice for the same match', () {
    final StoredMatchProgress matchProgress = StoredMatchProgress(
      profileApplied: true,
    );

    final bool shouldApply = shouldApplyMatchProfileUpdates(
      previousState: null,
      nextState: _buildFinishedMatch(),
      matchProgress: matchProgress,
    );

    expect(shouldApply, isFalse);
  });
}
