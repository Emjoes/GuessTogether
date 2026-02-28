import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guesstogether/features/game/domain/game_models.dart';

const int _boardPickSeconds = 10;
const int _answerWindowSeconds = 12;
const int _answerRevealSeconds = 3;

enum GameViewRole { host, player }

final gameViewRoleProvider = StateProvider<GameViewRole>(
  (ref) => GameViewRole.host,
);

final localPlayerIdProvider = StateProvider<String>(
  (ref) => 'p1',
);

class GameController extends StateNotifier<GameState> {
  GameController() : super(GameState.initial()) {
    _restartTickerAligned();
  }

  Timer? _ticker;
  Timer? _phaseTimeoutTimer;

  void _restartTickerAligned() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer timer) {
    if (state.isMatchEnded || state.phase == GamePhase.waitingForHost) {
      return;
    }
    if (state.isPaused) {
      return;
    }
    if (state.phase == GamePhase.answerWindow &&
        state.pendingAnswerPlayerId != null) {
      if (state.pendingAnswerSecondsLeft <= 0) {
        _schedulePhaseTimeout();
        return;
      }
      final int nextPending = state.pendingAnswerSecondsLeft - 1;
      state = state.copyWith(pendingAnswerSecondsLeft: nextPending);
      if (nextPending <= 0) {
        _schedulePhaseTimeout();
      }
      return;
    }
    if (state.phaseSecondsLeft <= 0) {
      _schedulePhaseTimeout();
      return;
    }

    final int next = state.phaseSecondsLeft - 1;
    state = state.copyWith(phaseSecondsLeft: next);
    if (next <= 0) {
      _schedulePhaseTimeout();
    }
  }

  void _schedulePhaseTimeout() {
    _phaseTimeoutTimer?.cancel();
    final GamePhase phaseAtSchedule = state.phase;
    final bool pendingAtSchedule = state.phase == GamePhase.answerWindow &&
        state.pendingAnswerPlayerId != null;
    _phaseTimeoutTimer = Timer(const Duration(milliseconds: 120), () {
      if (state.phase != phaseAtSchedule) {
        return;
      }
      if (state.isPaused) {
        return;
      }
      if (phaseAtSchedule == GamePhase.answerWindow) {
        final bool pendingNow = state.pendingAnswerPlayerId != null;
        if (pendingNow != pendingAtSchedule) {
          return;
        }
        if (pendingNow && state.pendingAnswerSecondsLeft > 0) {
          return;
        }
        if (!pendingNow && state.phaseSecondsLeft > 0) {
          return;
        }
      } else if (state.phaseSecondsLeft > 0) {
        return;
      }
      _handlePhaseTimeout();
    });
  }

  void _handlePhaseTimeout() {
    switch (state.phase) {
      case GamePhase.boardSelection:
        _autoPickQuestion();
      case GamePhase.answerWindow:
        _handleAnswerWindowTimeout();
      case GamePhase.answerReveal:
        _returnToBoardOrFinish();
      case GamePhase.waitingForHost:
      case GamePhase.finished:
      case GamePhase.paused:
      case GamePhase.questionReveal:
        break;
    }
  }

  Future<void> startMatch() async {
    if (state.isMatchEnded) {
      _resetMatch();
    }
    if (state.phase != GamePhase.waitingForHost) {
      return;
    }
    state = state.copyWith(
      phase: GamePhase.boardSelection,
      phaseSecondsLeft: _boardPickSeconds,
      phaseSecondsTotal: _boardPickSeconds,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      lastCorrectAnswerPlayerId: null,
      lastEvent: '${_playerName(state.currentChooserId)} picks the next clue.',
    );
    _restartTickerAligned();
  }

  void togglePause() {
    if (state.isMatchEnded || state.phase == GamePhase.waitingForHost) {
      return;
    }

    if (state.isPaused) {
      state = state.copyWith(isPaused: false, lastEvent: 'Match resumed.');
      _restartTickerAligned();
      return;
    }

    state = state.copyWith(isPaused: true, lastEvent: 'Match paused by host.');
  }

  void chooseQuestion(
    String questionId, {
    required bool hostOverride,
  }) {
    if (state.phase != GamePhase.boardSelection ||
        state.isMatchEnded ||
        state.isPaused) {
      return;
    }

    final int index =
        state.boardQuestions.indexWhere((Question q) => q.id == questionId);
    if (index < 0) {
      return;
    }

    final Question selected = state.boardQuestions[index];
    if (selected.used) {
      return;
    }

    final List<Question> updatedBoard =
        List<Question>.from(state.boardQuestions);
    updatedBoard[index] = selected.copyWith(used: true);
    state = state.copyWith(
      boardQuestions: updatedBoard,
      currentQuestion: selected,
      questionOwnerId: state.currentChooserId,
      phase: GamePhase.answerWindow,
      phaseSecondsLeft: _answerWindowSeconds,
      phaseSecondsTotal: _answerWindowSeconds,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      pendingAnswerPlayerId: null,
      passedPlayerIds: const <String>[],
      wrongAnswerPlayerIds: const <String>[],
      lastCorrectAnswerPlayerId: null,
      lastEvent: hostOverride
          ? 'Host selected ${selected.category} for ${selected.value}. Players can answer now.'
          : '${_playerName(state.currentChooserId)} selected ${selected.category} for ${selected.value}. Players can answer now.',
    );
    _restartTickerAligned();
  }

  void requestAnswer(String playerId) {
    if (state.phase != GamePhase.answerWindow ||
        state.isPaused ||
        state.pendingAnswerPlayerId != null ||
        state.phaseSecondsLeft <= 0 ||
        state.currentQuestion == null) {
      return;
    }
    if (!_canPlayerAnswer(playerId)) {
      return;
    }
    state = state.copyWith(
      pendingAnswerPlayerId: playerId,
      pendingAnswerSecondsLeft: _answerWindowSeconds,
      pendingAnswerSecondsTotal: _answerWindowSeconds,
      lastCorrectAnswerPlayerId: null,
      lastEvent: '${_playerName(playerId)} is answering now.',
    );
    _restartTickerAligned();
  }

  void passQuestion(String playerId) {
    if (state.phase != GamePhase.answerWindow ||
        state.isPaused ||
        state.pendingAnswerPlayerId != null) {
      return;
    }
    if (!_canPlayerAnswer(playerId)) {
      return;
    }

    final List<String> passed = <String>[...state.passedPlayerIds, playerId];
    if (_allPlayersUnavailable(
      passedIds: passed,
      wrongIds: state.wrongAnswerPlayerIds,
    )) {
      state = state.copyWith(
        passedPlayerIds: passed,
        lastCorrectAnswerPlayerId: null,
      );
      _startAnswerReveal(
        lastEvent: 'All players passed or answered incorrectly.',
      );
      return;
    }

    state = state.copyWith(
      passedPlayerIds: passed,
      lastCorrectAnswerPlayerId: null,
      lastEvent: '${_playerName(playerId)} passed this clue.',
    );
  }

  void hostAcceptAnswer() {
    final String? answeringPlayerId = state.pendingAnswerPlayerId;
    final Question? question = state.currentQuestion;
    if (answeringPlayerId == null || question == null) {
      return;
    }

    final List<Player> updatedPlayers = state.players.map((Player player) {
      if (player.id != answeringPlayerId) {
        return player;
      }
      return player.copyWith(
        score: Scoring.applyAnswer(
          currentScore: player.score,
          correct: true,
          value: question.value,
        ),
      );
    }).toList();

    state = state.copyWith(
      players: updatedPlayers,
      currentChooserId: answeringPlayerId,
      pendingAnswerPlayerId: null,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      lastCorrectAnswerPlayerId: answeringPlayerId,
      isPaused: false,
    );
    _startAnswerReveal(lastEvent: 'Host accepted the answer.');
  }

  void hostRejectAnswer() {
    final String? answeringPlayerId = state.pendingAnswerPlayerId;
    final Question? question = state.currentQuestion;
    if (answeringPlayerId == null || question == null) {
      return;
    }

    final List<Player> updatedPlayers = state.players.map((Player player) {
      if (player.id != answeringPlayerId) {
        return player;
      }
      return player.copyWith(
        score: Scoring.applyAnswer(
          currentScore: player.score,
          correct: false,
          value: question.value,
        ),
      );
    }).toList();

    final List<String> wrong = <String>[
      ...state.wrongAnswerPlayerIds,
      answeringPlayerId,
    ];
    if (_allPlayersUnavailable(
      passedIds: state.passedPlayerIds,
      wrongIds: wrong,
    )) {
      state = state.copyWith(
        players: updatedPlayers,
        pendingAnswerPlayerId: null,
        pendingAnswerSecondsLeft: 0,
        pendingAnswerSecondsTotal: 0,
        wrongAnswerPlayerIds: wrong,
        lastCorrectAnswerPlayerId: null,
        isPaused: false,
      );
      _startAnswerReveal(lastEvent: 'No more available answers.');
      return;
    }

    state = state.copyWith(
      players: updatedPlayers,
      pendingAnswerPlayerId: null,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      wrongAnswerPlayerIds: wrong,
      lastCorrectAnswerPlayerId: null,
      isPaused: false,
      lastEvent: 'Host rejected the answer.',
    );
    if (state.phaseSecondsLeft <= 0) {
      _schedulePhaseTimeout();
      return;
    }
    _restartTickerAligned();
  }

  void _handleAnswerWindowTimeout() {
    final String? answeringPlayerId = state.pendingAnswerPlayerId;
    final Question? question = state.currentQuestion;
    if (answeringPlayerId == null || question == null) {
      _startAnswerReveal(lastEvent: 'Answer time is over.');
      return;
    }

    final List<Player> updatedPlayers = state.players.map((Player player) {
      if (player.id != answeringPlayerId) {
        return player;
      }
      return player.copyWith(
        score: Scoring.applyAnswer(
          currentScore: player.score,
          correct: false,
          value: question.value,
        ),
      );
    }).toList();

    final List<String> wrong = <String>[
      ...state.wrongAnswerPlayerIds
          .where((String id) => id != answeringPlayerId),
      answeringPlayerId,
    ];
    if (_allPlayersUnavailable(
      passedIds: state.passedPlayerIds,
      wrongIds: wrong,
    )) {
      state = state.copyWith(
        players: updatedPlayers,
        pendingAnswerPlayerId: null,
        pendingAnswerSecondsLeft: 0,
        pendingAnswerSecondsTotal: 0,
        wrongAnswerPlayerIds: wrong,
        lastCorrectAnswerPlayerId: null,
        isPaused: false,
      );
      _startAnswerReveal(
          lastEvent: '${_playerName(answeringPlayerId)} timed out.');
      return;
    }

    state = state.copyWith(
      players: updatedPlayers,
      pendingAnswerPlayerId: null,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      wrongAnswerPlayerIds: wrong,
      lastCorrectAnswerPlayerId: null,
      isPaused: false,
      lastEvent:
          '${_playerName(answeringPlayerId)} timed out and got a wrong answer.',
    );
    if (state.phaseSecondsLeft <= 0) {
      _schedulePhaseTimeout();
      return;
    }
    _restartTickerAligned();
  }

  void setPlayerScore({
    required String playerId,
    required int score,
  }) {
    final List<Player> updated = state.players.map((Player player) {
      if (player.id != playerId) {
        return player;
      }
      return player.copyWith(score: score);
    }).toList();

    state = state.copyWith(
      players: updated,
      lastEvent: 'Host manually changed ${_playerName(playerId)} score.',
    );
  }

  void _startAnswerReveal({
    required String lastEvent,
  }) {
    state = state.copyWith(
      phase: GamePhase.answerReveal,
      phaseSecondsLeft: _answerRevealSeconds,
      phaseSecondsTotal: _answerRevealSeconds,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      pendingAnswerPlayerId: null,
      isPaused: false,
      lastEvent: lastEvent,
    );
    _restartTickerAligned();
  }

  void _returnToBoardOrFinish() {
    if (!state.hasBoardQuestionsLeft) {
      final List<Player> sorted = List<Player>.from(state.players)
        ..sort((Player a, Player b) => b.score.compareTo(a.score));
      state = state.copyWith(
        phase: GamePhase.finished,
        isMatchEnded: true,
        winnerId: sorted.isEmpty ? null : sorted.first.id,
        clearCurrentQuestion: true,
        phaseSecondsLeft: 0,
        phaseSecondsTotal: 0,
        pendingAnswerSecondsLeft: 0,
        pendingAnswerSecondsTotal: 0,
        pendingAnswerPlayerId: null,
        passedPlayerIds: const <String>[],
        wrongAnswerPlayerIds: const <String>[],
        lastCorrectAnswerPlayerId: null,
        isPaused: false,
        lastEvent: 'Match is over.',
      );
      return;
    }

    state = state.copyWith(
      phase: GamePhase.boardSelection,
      clearCurrentQuestion: true,
      phaseSecondsLeft: _boardPickSeconds,
      phaseSecondsTotal: _boardPickSeconds,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      pendingAnswerPlayerId: null,
      passedPlayerIds: const <String>[],
      wrongAnswerPlayerIds: const <String>[],
      lastCorrectAnswerPlayerId: null,
      currentChooserId: state.currentChooserId,
      isPaused: false,
      lastEvent: '${_playerName(state.currentChooserId)} picks next clue.',
    );
    _restartTickerAligned();
  }

  void _autoPickQuestion() {
    final List<Question> remaining = state.boardQuestions
        .where((Question question) => !question.used)
        .toList()
      ..sort((Question a, Question b) => a.value.compareTo(b.value));
    if (remaining.isEmpty) {
      _returnToBoardOrFinish();
      return;
    }
    chooseQuestion(remaining.first.id, hostOverride: true);
    state =
        state.copyWith(lastEvent: 'Time is up. Question was auto-selected.');
  }

  void _resetMatch() {
    state = GameState.initial();
  }

  bool _canPlayerAnswer(String playerId) {
    if (state.currentQuestion == null) {
      return false;
    }
    if (state.passedPlayerIds.contains(playerId)) {
      return false;
    }
    if (state.wrongAnswerPlayerIds.contains(playerId)) {
      return false;
    }
    return state.players.any((Player p) => p.id == playerId);
  }

  bool _allPlayersUnavailable({
    required List<String> passedIds,
    required List<String> wrongIds,
  }) {
    for (final Player player in state.players) {
      if (!passedIds.contains(player.id) && !wrongIds.contains(player.id)) {
        return false;
      }
    }
    return true;
  }

  String _playerName(String playerId) {
    return state.players
        .firstWhere(
          (Player p) => p.id == playerId,
          orElse: () => const Player(id: '', name: 'Player', score: 0),
        )
        .name;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _phaseTimeoutTimer?.cancel();
    super.dispose();
  }
}

final gameControllerProvider =
    StateNotifierProvider.autoDispose<GameController, GameState>(
  (ref) => GameController(),
);
