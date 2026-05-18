import 'package:guesstogether/features/game/domain/game_models.dart';

class GameStateMachine {
  static const int boardPickSeconds = 10;
  static const int questionRevealSeconds = 2;
  static const int answerWindowSeconds = 12;
  static const int answerRevealSeconds = 3;
  static const int roundAnnouncementSeconds = 3;

  static GameState initialMatch(
    List<Player> players, {
    List<Question>? boardQuestions,
  }) {
    final List<Player> safePlayers = players.isEmpty
        ? const <Player>[
            Player(id: 'p1', name: 'Serge', score: 0),
            Player(id: 'p2', name: 'Ivy', score: 0),
          ]
        : players;
    return GameState.initial(
      players: safePlayers,
      boardQuestions: boardQuestions,
    ).copyWith(
      phase: GamePhase.boardSelection,
      phaseSecondsLeft: boardPickSeconds,
      phaseSecondsTotal: boardPickSeconds,
      lastEvent:
          '${_playerName(safePlayers, safePlayers.first.id)} picks the next clue.',
    );
  }

  static GameState tick(GameState state) {
    if (state.isMatchEnded || state.isPaused) {
      return state;
    }
    // No timer for interactive special phases — wait for explicit actions.
    if (state.phase == GamePhase.catInBagTransfer ||
        state.phase == GamePhase.auctionBidding) {
      return state;
    }
    if (state.phase == GamePhase.answerWindow &&
        state.pendingAnswerPlayerId != null) {
      if (state.pendingAnswerSecondsLeft <= 1) {
        return _handlePhaseTimeout(
          state.copyWith(
            pendingAnswerSecondsLeft: 0,
          ),
        );
      }
      return state.copyWith(
        pendingAnswerSecondsLeft: state.pendingAnswerSecondsLeft - 1,
      );
    }
    if (state.phaseSecondsLeft <= 1) {
      return _handlePhaseTimeout(
        state.copyWith(
          phaseSecondsLeft: 0,
        ),
      );
    }
    return state.copyWith(
      phaseSecondsLeft: state.phaseSecondsLeft - 1,
    );
  }

  static GameState togglePause(GameState state) {
    if (state.isMatchEnded || state.phase == GamePhase.waitingForHost) {
      return state;
    }
    if (state.isPaused) {
      return state.copyWith(
        isPaused: false,
        lastEvent: 'Match resumed.',
      );
    }
    return state.copyWith(
      isPaused: true,
      lastEvent: 'Match paused by host.',
    );
  }

  static GameState chooseQuestion(
    GameState state, {
    required String questionId,
    required bool hostOverride,
  }) {
    if (state.phase != GamePhase.boardSelection ||
        state.isMatchEnded ||
        state.isPaused) {
      return state;
    }

    final int index =
        state.boardQuestions.indexWhere((Question q) => q.id == questionId);
    if (index < 0) {
      return state;
    }

    final Question selected = state.boardQuestions[index];
    if (selected.used || selected.round != state.round) {
      return state;
    }

    final List<Question> updatedBoard =
        List<Question>.from(state.boardQuestions);
    updatedBoard[index] = selected.copyWith(used: true);

    final GameState base = state.copyWith(
      boardQuestions: updatedBoard,
      currentQuestion: selected,
      questionOwnerId: state.currentChooserId,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      pendingAnswerPlayerId: null,
      passedPlayerIds: const <String>[],
      wrongAnswerPlayerIds: const <String>[],
      lastCorrectAnswerPlayerId: null,
      auctionBids: const <String, int>{},
      auctionPassedPlayerIds: const <String>[],
      isPaused: false,
    );

    final String chooserName = hostOverride
        ? 'Host'
        : _playerName(state.players, state.currentChooserId);

    switch (selected.type) {
      case QuestionType.catInBag:
        return base.copyWith(
          phase: GamePhase.catInBagTransfer,
          phaseSecondsLeft: 0,
          phaseSecondsTotal: 0,
          lastEvent:
              '$chooserName selected ${selected.category} — Кот в мешке!',
        );
      case QuestionType.auction:
        return base.copyWith(
          phase: GamePhase.auctionBidding,
          phaseSecondsLeft: 0,
          phaseSecondsTotal: 0,
          lastEvent:
              '$chooserName selected ${selected.category} — Вопрос со ставкой!',
        );
      case QuestionType.normal:
        return base.copyWith(
          phase: GamePhase.questionReveal,
          phaseSecondsLeft: questionRevealSeconds,
          phaseSecondsTotal: questionRevealSeconds,
          lastEvent: hostOverride
              ? 'Host selected ${selected.category} for ${selected.value}.'
              : '${_playerName(state.players, state.currentChooserId)} selected ${selected.category} for ${selected.value}.',
        );
    }
  }

  /// Host assigns the Cat-in-Bag question to [targetPlayerId].
  static GameState transferCatInBag(GameState state, String targetPlayerId) {
    if (state.phase != GamePhase.catInBagTransfer || state.isMatchEnded) {
      return state;
    }
    if (!state.players.any((Player p) => p.id == targetPlayerId)) {
      return state;
    }
    return state.copyWith(
      questionOwnerId: targetPlayerId,
      phase: GamePhase.questionReveal,
      phaseSecondsLeft: questionRevealSeconds,
      phaseSecondsTotal: questionRevealSeconds,
      lastEvent:
          '${_playerName(state.players, targetPlayerId)} gets the Cat-in-Bag question.',
    );
  }

  /// A player places an auction bid.
  static GameState placeBid(GameState state, String playerId, int wager) {
    if (state.phase != GamePhase.auctionBidding || state.isMatchEnded) {
      return state;
    }
    final Question? question = state.currentQuestion;
    if (question == null) return state;
    if (!_isEligibleToBid(state, playerId)) return state;

    final Player? player = state.players
        .cast<Player?>()
        .firstWhere((Player? p) => p?.id == playerId, orElse: () => null);
    if (player == null) return state;

    final bool isChooser = playerId == state.currentChooserId;
    // Non-chooser must go all-in (their full score).
    final int minWager = isChooser ? question.value : player.score;
    final int maxWager = player.score > 0 ? player.score : question.value;
    final int clampedWager = wager.clamp(minWager, maxWager);

    final Map<String, int> updatedBids =
        Map<String, int>.from(state.auctionBids);
    updatedBids[playerId] = clampedWager;

    final GameState updated = state.copyWith(
      auctionBids: updatedBids,
      lastEvent:
          '${_playerName(state.players, playerId)} bid $clampedWager.',
    );
    return _checkAuctionComplete(updated);
  }

  /// A player passes (skips) the auction.
  static GameState passAuction(GameState state, String playerId) {
    if (state.phase != GamePhase.auctionBidding || state.isMatchEnded) {
      return state;
    }
    if (!_isEligibleToBid(state, playerId)) return state;

    final List<String> passed = <String>[
      ...state.auctionPassedPlayerIds,
      playerId,
    ];
    final GameState updated = state.copyWith(
      auctionPassedPlayerIds: passed,
      lastEvent:
          '${_playerName(state.players, playerId)} passed the auction.',
    );
    return _checkAuctionComplete(updated);
  }

  static GameState requestAnswer(GameState state, String playerId) {
    if (state.phase != GamePhase.answerWindow ||
        state.isPaused ||
        state.pendingAnswerPlayerId != null ||
        state.phaseSecondsLeft <= 0 ||
        state.currentQuestion == null) {
      return state;
    }
    if (!_canPlayerAnswer(state, playerId)) {
      return state;
    }
    return state.copyWith(
      pendingAnswerPlayerId: playerId,
      pendingAnswerSecondsLeft: answerWindowSeconds,
      pendingAnswerSecondsTotal: answerWindowSeconds,
      lastCorrectAnswerPlayerId: null,
      lastEvent: '${_playerName(state.players, playerId)} is answering now.',
    );
  }

  static GameState passQuestion(GameState state, String playerId) {
    if (state.phase != GamePhase.answerWindow ||
        state.isPaused ||
        state.pendingAnswerPlayerId != null) {
      return state;
    }
    if (!_canPlayerAnswer(state, playerId)) {
      return state;
    }

    final List<String> passed = <String>[...state.passedPlayerIds, playerId];
    if (_allPlayersUnavailable(
      state.players,
      passedIds: passed,
      wrongIds: state.wrongAnswerPlayerIds,
    )) {
      return _startAnswerReveal(
        state.copyWith(
          passedPlayerIds: passed,
          lastCorrectAnswerPlayerId: null,
        ),
        lastEvent: 'All players passed or answered incorrectly.',
      );
    }

    return state.copyWith(
      passedPlayerIds: passed,
      lastCorrectAnswerPlayerId: null,
      lastEvent: '${_playerName(state.players, playerId)} passed this clue.',
    );
  }

  static GameState acceptAnswer(GameState state) {
    final String? answeringPlayerId = state.pendingAnswerPlayerId;
    final Question? question = state.currentQuestion;
    if (answeringPlayerId == null || question == null) {
      return state;
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

    final GameState next = state.copyWith(
      players: updatedPlayers,
      currentChooserId: answeringPlayerId,
      pendingAnswerPlayerId: null,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      lastCorrectAnswerPlayerId: answeringPlayerId,
      isPaused: false,
    );
    return _startAnswerReveal(next, lastEvent: 'Host accepted the answer.');
  }

  static GameState rejectAnswer(GameState state) {
    final String? answeringPlayerId = state.pendingAnswerPlayerId;
    final Question? question = state.currentQuestion;
    if (answeringPlayerId == null || question == null) {
      return state;
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
    final GameState next = state.copyWith(
      players: updatedPlayers,
      pendingAnswerPlayerId: null,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      wrongAnswerPlayerIds: wrong,
      lastCorrectAnswerPlayerId: null,
      isPaused: false,
    );
    if (_allPlayersUnavailable(
      state.players,
      passedIds: state.passedPlayerIds,
      wrongIds: wrong,
    )) {
      return _startAnswerReveal(next, lastEvent: 'No more available answers.');
    }
    return next.copyWith(lastEvent: 'Host rejected the answer.');
  }

  static GameState _handlePhaseTimeout(GameState state) {
    switch (state.phase) {
      case GamePhase.boardSelection:
        return _autoPickQuestion(state);
      case GamePhase.catInBagTransfer:
      case GamePhase.auctionBidding:
        return state;
      case GamePhase.questionReveal:
        return _startAnswerWindow(state);
      case GamePhase.answerWindow:
        return _handleAnswerWindowTimeout(state);
      case GamePhase.answerReveal:
        return _returnToBoardOrFinish(state);
      case GamePhase.roundAnnouncement:
        return _proceedToBoardSelection(state);
      case GamePhase.waitingForHost:
      case GamePhase.finished:
      case GamePhase.paused:
        return state;
    }
  }

  static GameState _startAnswerWindow(GameState state) {
    final Question? question = state.currentQuestion;
    if (question == null) {
      return state.copyWith(
        phase: GamePhase.boardSelection,
        phaseSecondsLeft: boardPickSeconds,
        phaseSecondsTotal: boardPickSeconds,
        pendingAnswerSecondsLeft: 0,
        pendingAnswerSecondsTotal: 0,
        pendingAnswerPlayerId: null,
        passedPlayerIds: const <String>[],
        wrongAnswerPlayerIds: const <String>[],
        lastCorrectAnswerPlayerId: null,
        isPaused: false,
      );
    }

    return state.copyWith(
      phase: GamePhase.answerWindow,
      phaseSecondsLeft: answerWindowSeconds,
      phaseSecondsTotal: answerWindowSeconds,
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
  }

  static GameState setPlayerScore(
    GameState state, {
    required String playerId,
    required int score,
  }) {
    final List<Player> updatedPlayers = state.players.map((Player player) {
      if (player.id != playerId) {
        return player;
      }
      return player.copyWith(score: score);
    }).toList(growable: false);

    return state.copyWith(
      players: updatedPlayers,
      lastEvent:
          'Host manually changed ${_playerName(updatedPlayers, playerId)} score.',
    );
  }

  static GameState skipQuestion(GameState state) {
    if (state.isMatchEnded || state.isPaused || state.currentQuestion == null) {
      return state;
    }
    switch (state.phase) {
      case GamePhase.catInBagTransfer:
      case GamePhase.auctionBidding:
        // Cancel the special question and return to board.
        return _returnToBoardOrFinish(
          state.copyWith(
            pendingAnswerSecondsLeft: 0,
            pendingAnswerSecondsTotal: 0,
            pendingAnswerPlayerId: null,
            passedPlayerIds: const <String>[],
            wrongAnswerPlayerIds: const <String>[],
            lastCorrectAnswerPlayerId: null,
            auctionBids: const <String, int>{},
            auctionPassedPlayerIds: const <String>[],
            isPaused: false,
          ),
        );
      case GamePhase.questionReveal:
        // Cancel the reveal and go straight back to the board.
        return _returnToBoardOrFinish(
          state.copyWith(
            pendingAnswerSecondsLeft: 0,
            pendingAnswerSecondsTotal: 0,
            pendingAnswerPlayerId: null,
            passedPlayerIds: const <String>[],
            wrongAnswerPlayerIds: const <String>[],
            lastCorrectAnswerPlayerId: null,
            isPaused: false,
          ),
        );
      case GamePhase.answerWindow:
        // First show the correct answer, then let the host skip to board.
        return _startAnswerReveal(
          state.copyWith(
            pendingAnswerSecondsLeft: 0,
            pendingAnswerSecondsTotal: 0,
            pendingAnswerPlayerId: null,
            passedPlayerIds: const <String>[],
            wrongAnswerPlayerIds: const <String>[],
            lastCorrectAnswerPlayerId: null,
            isPaused: false,
          ),
          lastEvent: 'Question skipped.',
        );
      case GamePhase.answerReveal:
        // Answer has been shown — proceed to board.
        return _returnToBoardOrFinish(
          state.copyWith(
            pendingAnswerSecondsLeft: 0,
            pendingAnswerSecondsTotal: 0,
            pendingAnswerPlayerId: null,
            passedPlayerIds: const <String>[],
            wrongAnswerPlayerIds: const <String>[],
            lastCorrectAnswerPlayerId: null,
            isPaused: false,
          ),
        );
      case GamePhase.waitingForHost:
      case GamePhase.boardSelection:
      case GamePhase.roundAnnouncement:
      case GamePhase.paused:
      case GamePhase.finished:
        return state;
    }
  }

  static GameState skipRound(GameState state) {
    if (state.isMatchEnded || state.isPaused) {
      return state;
    }

    final List<Question> updatedBoard = state.boardQuestions
        .map(
          (Question question) => question.round == state.round
              ? question.copyWith(used: true)
              : question,
        )
        .toList(growable: false);
    final GameState skippedState = state.copyWith(
      boardQuestions: updatedBoard,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      pendingAnswerPlayerId: null,
      passedPlayerIds: const <String>[],
      wrongAnswerPlayerIds: const <String>[],
      lastCorrectAnswerPlayerId: null,
      auctionBids: const <String, int>{},
      auctionPassedPlayerIds: const <String>[],
      isPaused: false,
    );
    final int? nextRound = skippedState.nextRoundNumber;
    if (nextRound != null) {
      // Skip directly to board without round announcement when host skips.
      return skippedState.copyWith(
        phase: GamePhase.boardSelection,
        round: nextRound,
        clearCurrentQuestion: true,
        phaseSecondsLeft: boardPickSeconds,
        phaseSecondsTotal: boardPickSeconds,
        lastEvent: 'Round $nextRound begins.',
      );
    }

    final List<Player> sorted = List<Player>.from(skippedState.players)
      ..sort((Player a, Player b) => b.score.compareTo(a.score));
    return skippedState.copyWith(
      phase: GamePhase.finished,
      isMatchEnded: true,
      winnerId: sorted.isEmpty ? null : sorted.first.id,
      clearCurrentQuestion: true,
      phaseSecondsLeft: 0,
      phaseSecondsTotal: 0,
      lastEvent: 'Match is over.',
    );
  }

  static GameState _checkAuctionComplete(GameState state) {
    final Question? question = state.currentQuestion;
    if (question == null) return _returnToBoardOrFinish(state);

    final String chooserId = state.currentChooserId;
    final bool chooserDone = state.auctionBids.containsKey(chooserId) ||
        state.auctionPassedPlayerIds.contains(chooserId);

    if (!chooserDone) return state;

    if (state.auctionPassedPlayerIds.contains(chooserId)) {
      // Chooser passed — auction cancelled, reveal answer without scoring.
      return _startAnswerReveal(
        state.copyWith(lastCorrectAnswerPlayerId: null),
        lastEvent: 'The auction was passed.',
      );
    }

    final int chooserBid = state.auctionBids[chooserId]!;
    final Player? chooser = state.players
        .cast<Player?>()
        .firstWhere((Player? p) => p?.id == chooserId, orElse: () => null);
    final bool chooserAllIn =
        chooser != null && chooser.score > 0 && chooserBid >= chooser.score;

    if (!chooserAllIn) {
      return _startAuctionQuestion(
          state, winnerId: chooserId, wager: chooserBid);
    }

    // Chooser went all-in — check if all eligible non-choosers have responded.
    final List<Player> eligibleOthers = state.players
        .where((Player p) => p.id != chooserId && p.score > chooserBid)
        .toList();

    final bool allDone = eligibleOthers.every(
      (Player p) =>
          state.auctionBids.containsKey(p.id) ||
          state.auctionPassedPlayerIds.contains(p.id),
    );

    if (!allDone) return state;

    // All done — find highest bidder.
    String winnerId = chooserId;
    int highestBid = chooserBid;
    for (final MapEntry<String, int> entry in state.auctionBids.entries) {
      if (entry.value > highestBid) {
        highestBid = entry.value;
        winnerId = entry.key;
      }
    }

    return _startAuctionQuestion(state, winnerId: winnerId, wager: highestBid);
  }

  static GameState _startAuctionQuestion(
    GameState state, {
    required String winnerId,
    required int wager,
  }) {
    final Question? question = state.currentQuestion;
    if (question == null) return _returnToBoardOrFinish(state);

    // Replace question value with winning wager so existing scoring logic works.
    final Question wageredQuestion = question.copyWith(value: wager);

    return state.copyWith(
      currentQuestion: wageredQuestion,
      questionOwnerId: winnerId,
      phase: GamePhase.questionReveal,
      phaseSecondsLeft: questionRevealSeconds,
      phaseSecondsTotal: questionRevealSeconds,
      auctionBids: const <String, int>{},
      auctionPassedPlayerIds: const <String>[],
      passedPlayerIds: const <String>[],
      wrongAnswerPlayerIds: const <String>[],
      lastCorrectAnswerPlayerId: null,
      isPaused: false,
      lastEvent:
          '${_playerName(state.players, winnerId)} won the auction with $wager points.',
    );
  }

  static bool _isEligibleToBid(GameState state, String playerId) {
    if (state.auctionBids.containsKey(playerId)) return false;
    if (state.auctionPassedPlayerIds.contains(playerId)) return false;

    final Player? player = state.players
        .cast<Player?>()
        .firstWhere((Player? p) => p?.id == playerId, orElse: () => null);
    if (player == null) return false;

    final bool isChooser = playerId == state.currentChooserId;
    if (isChooser) return true;

    // Non-choosers can only bid if chooser went all-in and they have more points.
    final int? chooserBid = state.auctionBids[state.currentChooserId];
    if (chooserBid == null) return false;

    final Player? chooser = state.players
        .cast<Player?>()
        .firstWhere(
            (Player? p) => p?.id == state.currentChooserId,
            orElse: () => null);
    if (chooser == null || chooser.score <= 0) return false;

    final bool chooserAllIn = chooserBid >= chooser.score;
    if (!chooserAllIn) return false;

    return player.score > chooserBid;
  }

  static GameState _handleAnswerWindowTimeout(GameState state) {
    final String? answeringPlayerId = state.pendingAnswerPlayerId;
    final Question? question = state.currentQuestion;
    if (answeringPlayerId == null || question == null) {
      return _startAnswerReveal(
        state,
        lastEvent: 'Answer time is over.',
      );
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
    final GameState next = state.copyWith(
      players: updatedPlayers,
      pendingAnswerPlayerId: null,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      wrongAnswerPlayerIds: wrong,
      lastCorrectAnswerPlayerId: null,
      isPaused: false,
    );
    if (_allPlayersUnavailable(
      state.players,
      passedIds: state.passedPlayerIds,
      wrongIds: wrong,
    )) {
      return _startAnswerReveal(
        next,
        lastEvent:
            '${_playerName(state.players, answeringPlayerId)} timed out.',
      );
    }

    return next.copyWith(
      lastEvent:
          '${_playerName(state.players, answeringPlayerId)} timed out and got a wrong answer.',
    );
  }

  static GameState _startAnswerReveal(
    GameState state, {
    required String lastEvent,
  }) {
    return state.copyWith(
      phase: GamePhase.answerReveal,
      phaseSecondsLeft: answerRevealSeconds,
      phaseSecondsTotal: answerRevealSeconds,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      pendingAnswerPlayerId: null,
      isPaused: false,
      lastEvent: lastEvent,
    );
  }

  static GameState _returnToBoardOrFinish(GameState state) {
    if (!state.hasBoardQuestionsLeft) {
      final int? nextRound = state.nextRoundNumber;
      if (nextRound != null) {
        return _startRoundAnnouncement(state, nextRound: nextRound);
      }
      final List<Player> sorted = List<Player>.from(state.players)
        ..sort((Player a, Player b) => b.score.compareTo(a.score));
      return state.copyWith(
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
    }

    return state.copyWith(
      phase: GamePhase.boardSelection,
      clearCurrentQuestion: true,
      phaseSecondsLeft: boardPickSeconds,
      phaseSecondsTotal: boardPickSeconds,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      pendingAnswerPlayerId: null,
      passedPlayerIds: const <String>[],
      wrongAnswerPlayerIds: const <String>[],
      lastCorrectAnswerPlayerId: null,
      isPaused: false,
      lastEvent:
          '${_playerName(state.players, state.currentChooserId)} picks next clue.',
    );
  }

  static GameState _startRoundAnnouncement(
    GameState state, {
    required int nextRound,
  }) {
    return state.copyWith(
      phase: GamePhase.roundAnnouncement,
      round: nextRound,
      clearCurrentQuestion: true,
      phaseSecondsLeft: roundAnnouncementSeconds,
      phaseSecondsTotal: roundAnnouncementSeconds,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      pendingAnswerPlayerId: null,
      passedPlayerIds: const <String>[],
      wrongAnswerPlayerIds: const <String>[],
      lastCorrectAnswerPlayerId: null,
      auctionBids: const <String, int>{},
      auctionPassedPlayerIds: const <String>[],
      isPaused: false,
      lastEvent: 'Round $nextRound begins.',
    );
  }

  static GameState _proceedToBoardSelection(GameState state) {
    return state.copyWith(
      phase: GamePhase.boardSelection,
      phaseSecondsLeft: boardPickSeconds,
      phaseSecondsTotal: boardPickSeconds,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      pendingAnswerPlayerId: null,
      passedPlayerIds: const <String>[],
      wrongAnswerPlayerIds: const <String>[],
      lastCorrectAnswerPlayerId: null,
      isPaused: false,
      lastEvent:
          '${_playerName(state.players, state.currentChooserId)} picks the next clue.',
    );
  }

  static GameState _autoPickQuestion(GameState state) {
    final List<Question> remaining = state.roundBoardQuestions
        .where((Question question) => !question.used)
        .toList()
      ..sort((Question a, Question b) => a.value.compareTo(b.value));
    if (remaining.isEmpty) {
      return _returnToBoardOrFinish(state);
    }
    return chooseQuestion(
      state,
      questionId: remaining.first.id,
      hostOverride: true,
    ).copyWith(
      lastEvent: 'Time is up. Question was auto-selected.',
    );
  }

  static bool _canPlayerAnswer(GameState state, String playerId) {
    if (state.currentQuestion == null) {
      return false;
    }
    if (state.passedPlayerIds.contains(playerId)) {
      return false;
    }
    if (state.wrongAnswerPlayerIds.contains(playerId)) {
      return false;
    }
    // For Cat-in-Bag, only the assigned player can answer.
    if (state.currentQuestion!.type == QuestionType.catInBag) {
      return playerId == state.questionOwnerId;
    }
    return state.players.any((Player p) => p.id == playerId);
  }

  static bool _allPlayersUnavailable(
    List<Player> players, {
    required List<String> passedIds,
    required List<String> wrongIds,
  }) {
    for (final Player player in players) {
      if (!passedIds.contains(player.id) && !wrongIds.contains(player.id)) {
        return false;
      }
    }
    return true;
  }

  static String _playerName(List<Player> players, String playerId) {
    return players
        .firstWhere(
          (Player p) => p.id == playerId,
          orElse: () => const Player(id: '', name: 'Player', score: 0),
        )
        .name;
  }
}
