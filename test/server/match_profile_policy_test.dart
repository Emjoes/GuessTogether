import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/data/api/game_api.dart';
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
  test('player leave during active match keeps participant in room', () {
    final bool shouldKeep = shouldKeepLeavingParticipantInRoom(
      isHost: false,
      roomStatus: RoomLifecycleStatus.inGame,
      gameState: GameState.initial(
        players: const <Player>[
          Player(id: 'p1', name: 'Alice', score: 0),
          Player(id: 'p2', name: 'Bob', score: 0),
        ],
      ),
    );

    expect(shouldKeep, isTrue);
  });

  test('host leave never keeps room participant attached', () {
    final bool shouldKeep = shouldKeepLeavingParticipantInRoom(
      isHost: true,
      roomStatus: RoomLifecycleStatus.inGame,
      gameState: _buildFinishedMatch(),
    );

    expect(shouldKeep, isFalse);
  });

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
