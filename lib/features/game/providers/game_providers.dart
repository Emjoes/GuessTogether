import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guesstogether/data/api/app_backend_api.dart';
import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/data/api/backend_models.dart';
import 'package:guesstogether/features/game/domain/game_models.dart';
import 'package:guesstogether/features/game/domain/game_state_machine.dart';
import 'package:guesstogether/features/lobby/providers/room_session_provider.dart';
import 'package:guesstogether/features/session/app_session_controller.dart';

const int _boardPickSeconds = 10;
const int _questionRevealSeconds = 2;
const int _answerWindowSeconds = 12;
const int _answerRevealSeconds = 3;

enum GameViewRole { host, player }

final gameViewRoleProvider = StateProvider<GameViewRole>(
  (ref) => GameViewRole.host,
);

final localPlayerIdProvider = StateProvider<String>(
  (ref) => 'p1',
);

final matchRoomClosedProvider = StateProvider<bool>((ref) => false);

enum MatchRoomClosedReason { hostLeft, connectionLost }

final matchRoomClosedReasonProvider =
    StateProvider<MatchRoomClosedReason?>((ref) => null);

final matchResultSnapshotProvider = StateProvider<GameState?>((ref) => null);

class GameController extends StateNotifier<GameState> {
  GameController({
    List<Player>? initialPlayers,
    bool enableLocalTimers = true,
  })  : _enableLocalTimers = enableLocalTimers,
        super(GameState.initial(players: initialPlayers)) {
    if (_enableLocalTimers) {
      _restartTickerAligned();
    }
  }

  final bool _enableLocalTimers;
  final Random _random = Random();
  Timer? _ticker;
  Timer? _phaseTimeoutTimer;

  void _stopTimers() {
    _ticker?.cancel();
    _phaseTimeoutTimer?.cancel();
  }

  void _restartTickerAligned() {
    if (!_enableLocalTimers) {
      return;
    }
    _stopTimers();
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
        return;
      case GamePhase.questionReveal:
        _startQuestionAnswerWindow();
        return;
      case GamePhase.answerWindow:
        _handleAnswerWindowTimeout();
        return;
      case GamePhase.answerReveal:
        _returnToBoardOrFinish();
        return;
      case GamePhase.waitingForHost:
      case GamePhase.finished:
      case GamePhase.paused:
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
    if (selected.used || selected.round != state.round) {
      return;
    }

    final List<Question> updatedBoard =
        List<Question>.from(state.boardQuestions);
    updatedBoard[index] = selected.copyWith(used: true);
    state = state.copyWith(
      boardQuestions: updatedBoard,
      currentQuestion: selected,
      questionOwnerId: state.currentChooserId,
      phase: GamePhase.questionReveal,
      phaseSecondsLeft: _questionRevealSeconds,
      phaseSecondsTotal: _questionRevealSeconds,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      pendingAnswerPlayerId: null,
      passedPlayerIds: const <String>[],
      wrongAnswerPlayerIds: const <String>[],
      lastCorrectAnswerPlayerId: null,
      lastEvent: hostOverride
          ? 'Host selected ${selected.category} for ${selected.value}.'
          : '${_playerName(state.currentChooserId)} selected ${selected.category} for ${selected.value}.',
    );
    _restartTickerAligned();
  }

  void pickRandomQuestion({
    required bool hostOverride,
  }) {
    if (state.phase != GamePhase.boardSelection ||
        state.isPaused ||
        state.isMatchEnded) {
      return;
    }
    final List<Question> availableQuestions = state.roundBoardQuestions
        .where((Question question) => !question.used)
        .toList(growable: false);
    if (availableQuestions.isEmpty) {
      return;
    }
    final Question selected =
        availableQuestions[_random.nextInt(availableQuestions.length)];
    chooseQuestion(selected.id, hostOverride: hostOverride);
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

  void _startQuestionAnswerWindow() {
    final Question? question = state.currentQuestion;
    if (question == null) {
      state = state.copyWith(
        phase: GamePhase.boardSelection,
        phaseSecondsLeft: _boardPickSeconds,
        phaseSecondsTotal: _boardPickSeconds,
        pendingAnswerSecondsLeft: 0,
        pendingAnswerSecondsTotal: 0,
        pendingAnswerPlayerId: null,
        passedPlayerIds: const <String>[],
        wrongAnswerPlayerIds: const <String>[],
        lastCorrectAnswerPlayerId: null,
        isPaused: false,
      );
      _restartTickerAligned();
      return;
    }

    state = state.copyWith(
      phase: GamePhase.answerWindow,
      phaseSecondsLeft: _answerWindowSeconds,
      phaseSecondsTotal: _answerWindowSeconds,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      pendingAnswerPlayerId: null,
      passedPlayerIds: const <String>[],
      wrongAnswerPlayerIds: const <String>[],
      lastCorrectAnswerPlayerId: null,
      isPaused: false,
      lastEvent:
          'Players can answer ${question.category} for ${question.value} now.',
    );
    _restartTickerAligned();
  }

  void setPlayerScore({
    required String playerId,
    required int score,
  }) {
    state = GameStateMachine.setPlayerScore(
      state,
      playerId: playerId,
      score: score,
    );
  }

  void skipCurrentQuestion() {
    final GameState next = GameStateMachine.skipQuestion(state);
    if (next == state) {
      return;
    }
    state = next;
    if (state.isMatchEnded || state.phase == GamePhase.waitingForHost) {
      _stopTimers();
      return;
    }
    _restartTickerAligned();
  }

  void skipRound() {
    final GameState next = GameStateMachine.skipRound(state);
    if (next == state) {
      return;
    }
    state = next;
    if (state.isMatchEnded || state.phase == GamePhase.waitingForHost) {
      _stopTimers();
      return;
    }
    _restartTickerAligned();
  }

  void finishMatchNow() {
    if (state.isMatchEnded) {
      return;
    }
    _stopTimers();
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
      lastEvent: 'Match was finished from debug panel.',
    );
  }

  Future<void> leaveMatch() async {}

  Future<void> resyncAfterResume({required bool isHost}) async {}

  Future<void> handleAppDetached({required bool isHost}) async {}

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
      final int? nextRound = state.nextRoundNumber;
      if (nextRound != null) {
        state = state.copyWith(
          phase: GamePhase.boardSelection,
          round: nextRound,
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
          lastEvent: 'Round $nextRound begins.',
        );
        _restartTickerAligned();
        return;
      }
      _stopTimers();
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
    final List<Question> remaining = state.roundBoardQuestions
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
    state = GameState.initial(
      players: state.players,
      boardQuestions: state.boardQuestions
          .map((Question question) => question.copyWith(used: false))
          .toList(growable: false),
    );
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
    _stopTimers();
    super.dispose();
  }
}

class OnlineGameController extends GameController {
  OnlineGameController(
    this._api,
    this.roomId, {
    required StateController<RoomDetails?> activeRoomController,
    required StateController<bool> matchRoomClosedController,
    required StateController<MatchRoomClosedReason?>
        matchRoomClosedReasonController,
    RoomDetails? initialRoom,
  })  : _activeRoomController = activeRoomController,
        _matchRoomClosedController = matchRoomClosedController,
        _matchRoomClosedReasonController = matchRoomClosedReasonController,
        super(
          initialPlayers: initialRoom?.playerParticipants
              .map(
                (RoomParticipant participant) => Player(
                  id: participant.id,
                  name: participant.displayName,
                  score: 0,
                ),
              )
              .toList(),
          enableLocalTimers: false,
        ) {
    _matchRoomClosedController.state = false;
    _matchRoomClosedReasonController.state = null;
    final GameState? initialGameState = initialRoom?.gameState;
    if (initialGameState != null) {
      state = initialGameState;
    }
    unawaited(_bootstrap());
  }

  final AppBackendApi _api;
  final String roomId;
  final StateController<RoomDetails?> _activeRoomController;
  final StateController<bool> _matchRoomClosedController;
  final StateController<MatchRoomClosedReason?>
      _matchRoomClosedReasonController;

  StreamSubscription<RoomRealtimeMessage>? _subscription;
  RoomRealtimeConnection? _connection;
  bool _isDisposed = false;
  bool _isResyncing = false;

  void _setActiveRoom(RoomDetails? room) {
    if (_isDisposed) {
      return;
    }
    _activeRoomController.state = room;
  }

  void _setMatchRoomClosed(bool value) {
    if (_isDisposed) {
      return;
    }
    _matchRoomClosedController.state = value;
  }

  void _setMatchRoomClosedReason(MatchRoomClosedReason? value) {
    if (_isDisposed) {
      return;
    }
    _matchRoomClosedReasonController.state = value;
  }

  Future<void> _disconnectRealtime() async {
    final StreamSubscription<RoomRealtimeMessage>? subscription = _subscription;
    final RoomRealtimeConnection? connection = _connection;
    _subscription = null;
    _connection = null;
    await subscription?.cancel();
    await connection?.close();
  }

  Future<void> _bootstrap() async {
    try {
      final RoomDetails room = await _api.loadRoom(roomId);
      if (_isDisposed) {
        return;
      }
      _setActiveRoom(room);
      if (room.gameState != null) {
        state = room.gameState!;
      }
      if (room.gameState?.isMatchEnded == true) {
        return;
      }
      if (_isDisposed) {
        return;
      }
      await _connect();
    } catch (_) {
      _setMatchRoomClosedReason(MatchRoomClosedReason.connectionLost);
      _setMatchRoomClosed(true);
      _setActiveRoom(null);
    }
  }

  Future<void> _connect() async {
    await _disconnectRealtime();
    if (_isDisposed) {
      return;
    }
    _connection = _api.connectToRoom(roomId);
    _subscription = _connection!.messages.listen(
      (RoomRealtimeMessage message) {
        if (_isDisposed) {
          return;
        }
        if (message.isClosed) {
          _setMatchRoomClosedReason(MatchRoomClosedReason.hostLeft);
          _setMatchRoomClosed(true);
          _setActiveRoom(null);
          return;
        }
        _setActiveRoom(message.room);
        final GameState? nextState =
            message.gameState ?? message.room.gameState;
        if (nextState != null) {
          state = nextState;
          if (nextState.isMatchEnded) {
            unawaited(_disconnectRealtime());
          }
        }
      },
      onError: (_) {
        _setMatchRoomClosedReason(MatchRoomClosedReason.connectionLost);
        _setMatchRoomClosed(true);
      },
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // The authoritative state is delivered by websocket updates. UI stays
      // in sync even if an individual command fails and is retried by user.
    }
  }

  @override
  Future<void> startMatch() {
    return _run(() => _api.startRoom(roomId));
  }

  @override
  void togglePause() {
    unawaited(_run(() => _api.togglePause(roomId)));
  }

  @override
  void chooseQuestion(
    String questionId, {
    required bool hostOverride,
  }) {
    unawaited(_run(() => _api.chooseQuestion(roomId, questionId)));
  }

  @override
  void pickRandomQuestion({
    required bool hostOverride,
  }) {
    if (state.phase != GamePhase.boardSelection ||
        state.isPaused ||
        state.isMatchEnded) {
      return;
    }
    final List<Question> availableQuestions = state.roundBoardQuestions
        .where((Question question) => !question.used)
        .toList(growable: false);
    if (availableQuestions.isEmpty) {
      return;
    }
    final Question selected =
        availableQuestions[Random().nextInt(availableQuestions.length)];
    chooseQuestion(selected.id, hostOverride: hostOverride);
  }

  @override
  void requestAnswer(String playerId) {
    unawaited(_run(() => _api.requestAnswer(roomId)));
  }

  @override
  void passQuestion(String playerId) {
    unawaited(_run(() => _api.passQuestion(roomId)));
  }

  @override
  void hostAcceptAnswer() {
    unawaited(_run(() => _api.acceptAnswer(roomId)));
  }

  @override
  void hostRejectAnswer() {
    unawaited(_run(() => _api.rejectAnswer(roomId)));
  }

  @override
  void setPlayerScore({
    required String playerId,
    required int score,
  }) {
    unawaited(_run(() => _api.setPlayerScore(roomId, playerId, score)));
  }

  @override
  void skipCurrentQuestion() {
    unawaited(_run(() => _api.skipQuestion(roomId)));
  }

  @override
  void skipRound() {
    unawaited(_run(() => _api.skipRound(roomId)));
  }

  @override
  Future<void> leaveMatch() async {
    try {
      await _api.leaveRoom(roomId);
    } catch (_) {
      // Room may already be deleted by the host disconnect rule.
    } finally {
      _setActiveRoom(null);
      _setMatchRoomClosedReason(null);
      _setMatchRoomClosed(false);
      await _disconnectRealtime();
    }
  }

  @override
  Future<void> resyncAfterResume({required bool isHost}) async {
    if (_isDisposed || _isResyncing) {
      return;
    }
    _isResyncing = true;
    try {
      final RoomDetails room = await _api.loadRoom(roomId);
      if (_isDisposed) {
        return;
      }
      _setActiveRoom(room);
      _setMatchRoomClosed(false);
      _setMatchRoomClosedReason(null);
      final GameState? nextState = room.gameState;
      if (nextState != null) {
        state = nextState;
      }
      if (nextState?.isMatchEnded == true) {
        await _disconnectRealtime();
        return;
      }
      await _connect();
    } on BackendException catch (error) {
      if (_isDisposed) {
        return;
      }
      if (error.statusCode == 404 || error.statusCode == 403) {
        _setActiveRoom(null);
        _setMatchRoomClosedReason(
          isHost
              ? MatchRoomClosedReason.connectionLost
              : MatchRoomClosedReason.hostLeft,
        );
        _setMatchRoomClosed(true);
      }
    } catch (_) {
      // Keep the last known state and retry on the next foreground resume.
    } finally {
      _isResyncing = false;
    }
  }

  @override
  Future<void> handleAppDetached({required bool isHost}) async {
    if (isHost) {
      await leaveMatch();
      return;
    }
    await _disconnectRealtime();
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_disconnectRealtime());
    super.dispose();
  }
}

final gameControllerProvider =
    StateNotifierProvider.autoDispose<GameController, GameState>(
  (ref) {
    final room = ref.read(activeRoomProvider);
    final AppBackendApi api = ref.watch(appBackendApiProvider);
    final String? roomId = room?.summary.id;
    if (roomId != null && roomId.isNotEmpty) {
      return OnlineGameController(
        api,
        roomId,
        activeRoomController: ref.read(activeRoomProvider.notifier),
        matchRoomClosedController: ref.read(matchRoomClosedProvider.notifier),
        matchRoomClosedReasonController:
            ref.read(matchRoomClosedReasonProvider.notifier),
        initialRoom: room,
      );
    }
    final List<Player>? initialPlayers = room?.participants
        .where((RoomParticipant participant) => !participant.isHost)
        .map(
          (RoomParticipant participant) => Player(
            id: participant.id,
            name: participant.displayName,
            score: 0,
          ),
        )
        .toList();
    return GameController(initialPlayers: initialPlayers);
  },
);
