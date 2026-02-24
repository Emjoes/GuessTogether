import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guesstogether/data/api/mock_ws_adapter.dart';
import 'package:guesstogether/data/api/realtime_adapter.dart';
import 'package:guesstogether/services/mock_match_host.dart';
import 'package:guesstogether/services/mock_ws_messages.dart';
import 'package:guesstogether/features/game/domain/game_models.dart';

final mockMatchHostProvider = Provider<MockMatchHost>((ref) {
  final host = MockMatchHost();
  ref.onDispose(host.dispose);
  return host;
});

final mockWsAdapterProvider = Provider<MockWebSocketAdapter>((ref) {
  return MockWebSocketAdapter(ref.read(mockMatchHostProvider));
});

class GameController extends StateNotifier<GameState> {
  GameController(this._ws) : super(GameState.initial()) {
    _sub = _ws.messages.listen(_handleMessage);
  }

  final RealtimeAdapter _ws;
  StreamSubscription<WsMessage>? _sub;
  Timer? _timer;

  void _handleMessage(WsMessage message) {
    if (message is RoomUpdateMessage) {
      state = state.copyWith(
        players: message.players
            .map(
              (WsPlayer p) => Player(
                id: p.id,
                name: p.name,
                score: p.score,
              ),
            )
            .toList(),
      );
    } else if (message is QuestionMessage) {
      final q = Question(
        id: message.id,
        text: message.text,
        category: message.category,
        value: message.value,
      );
      state = state.copyWith(
        currentQuestion: q,
        remainingSeconds: 20,
        isAnswering: true,
      );
      _startTimer();
    } else if (message is AnswerResultMessage) {
      final List<Player> updatedPlayers = state.players.map((Player p) {
        if (p.id == message.playerId) {
          final newScore = Scoring.applyAnswer(
            currentScore: p.score,
            correct: message.correct,
            value: message.delta,
          );
          return p.copyWith(score: newScore);
        }
        return p;
      }).toList();
      state = state.copyWith(players: updatedPlayers);
    } else if (message is ScoreUpdateMessage) {
      final Map<String, int> byId = <String, int>{
        for (final WsScore s in message.scores) s.playerId: s.score,
      };
      final List<Player> updated = state.players
          .map(
            (Player p) =>
                byId.containsKey(p.id) ? p.copyWith(score: byId[p.id]) : p,
          )
          .toList();
      state = state.copyWith(players: updated);
    } else if (message is MatchEndMessage) {
      _timer?.cancel();
      state = state.copyWith(
        isMatchEnded: true,
        winnerId: message.winnerId,
        clearCurrentQuestion: true,
        remainingSeconds: 0,
        isAnswering: false,
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (state.remainingSeconds <= 1) {
        t.cancel();
        state = state.copyWith(remainingSeconds: 0, isAnswering: false);
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  Future<void> startMatch() async {
    await _ws.start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}

final gameControllerProvider = StateNotifierProvider<GameController, GameState>(
  (ref) => GameController(ref.read(mockWsAdapterProvider)),
);
