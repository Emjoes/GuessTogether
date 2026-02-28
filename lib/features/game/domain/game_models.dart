import 'package:equatable/equatable.dart';

enum GamePhase {
  waitingForHost,
  boardSelection,
  questionReveal,
  answerWindow,
  answerReveal,
  paused,
  finished,
}

class Player extends Equatable {
  const Player({
    required this.id,
    required this.name,
    required this.score,
  });

  final String id;
  final String name;
  final int score;

  Player copyWith({
    String? name,
    int? score,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      score: score ?? this.score,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, name, score];
}

class Question extends Equatable {
  const Question({
    required this.id,
    required this.text,
    required this.answer,
    required this.category,
    required this.value,
    required this.used,
  });

  final String id;
  final String text;
  final String answer;
  final String category;
  final int value;
  final bool used;

  Question copyWith({
    String? text,
    String? answer,
    String? category,
    int? value,
    bool? used,
  }) {
    return Question(
      id: id,
      text: text ?? this.text,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      value: value ?? this.value,
      used: used ?? this.used,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, text, answer, category, value, used];
}

class GameState extends Equatable {
  const GameState({
    required this.players,
    required this.boardQuestions,
    required this.currentQuestion,
    required this.phase,
    required this.isPaused,
    required this.round,
    required this.currentChooserId,
    required this.questionOwnerId,
    required this.phaseSecondsLeft,
    required this.phaseSecondsTotal,
    required this.pendingAnswerSecondsLeft,
    required this.pendingAnswerSecondsTotal,
    required this.pendingAnswerPlayerId,
    required this.passedPlayerIds,
    required this.wrongAnswerPlayerIds,
    required this.lastCorrectAnswerPlayerId,
    required this.isMatchEnded,
    required this.winnerId,
    required this.lastEvent,
  });

  factory GameState.initial() {
    const List<Player> players = <Player>[
      Player(id: 'p1', name: 'Serge', score: 0),
      Player(id: 'p2', name: 'Ivy', score: 0),
      Player(id: 'p3', name: 'Max', score: 0),
      Player(id: 'p4', name: 'Nova', score: 0),
    ];
    return GameState(
      players: players,
      boardQuestions: _buildRoundBoard(),
      currentQuestion: null,
      phase: GamePhase.waitingForHost,
      isPaused: false,
      round: 1,
      currentChooserId: players.first.id,
      questionOwnerId: players.first.id,
      phaseSecondsLeft: 0,
      phaseSecondsTotal: 0,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 0,
      pendingAnswerPlayerId: null,
      passedPlayerIds: const <String>[],
      wrongAnswerPlayerIds: const <String>[],
      lastCorrectAnswerPlayerId: null,
      isMatchEnded: false,
      winnerId: null,
      lastEvent: 'Host should start the match',
    );
  }

  final List<Player> players;
  final List<Question> boardQuestions;
  final Question? currentQuestion;
  final GamePhase phase;
  final bool isPaused;
  final int round;
  final String currentChooserId;
  final String questionOwnerId;
  final int phaseSecondsLeft;
  final int phaseSecondsTotal;
  final int pendingAnswerSecondsLeft;
  final int pendingAnswerSecondsTotal;
  final String? pendingAnswerPlayerId;
  final List<String> passedPlayerIds;
  final List<String> wrongAnswerPlayerIds;
  final String? lastCorrectAnswerPlayerId;
  final bool isMatchEnded;
  final String? winnerId;
  final String lastEvent;

  int get remainingSeconds => phaseSecondsLeft;
  bool get isAnswering => phase == GamePhase.answerWindow;
  bool get hasBoardQuestionsLeft => boardQuestions.any((Question q) => !q.used);
  String? get currentAnswerTurnPlayerId {
    if (phase != GamePhase.answerWindow) {
      return null;
    }
    if (pendingAnswerPlayerId != null) {
      return pendingAnswerPlayerId;
    }
    if (players.isEmpty) {
      return null;
    }

    int startIndex =
        players.indexWhere((Player player) => player.id == questionOwnerId);
    if (startIndex < 0) {
      startIndex =
          players.indexWhere((Player player) => player.id == currentChooserId);
    }
    if (startIndex < 0) {
      startIndex = 0;
    }

    for (int offset = 0; offset < players.length; offset++) {
      final String candidateId =
          players[(startIndex + offset) % players.length].id;
      if (passedPlayerIds.contains(candidateId)) {
        continue;
      }
      if (wrongAnswerPlayerIds.contains(candidateId)) {
        continue;
      }
      return candidateId;
    }
    return null;
  }

  GameState copyWith({
    List<Player>? players,
    List<Question>? boardQuestions,
    Question? currentQuestion,
    bool clearCurrentQuestion = false,
    GamePhase? phase,
    bool? isPaused,
    int? round,
    String? currentChooserId,
    String? questionOwnerId,
    int? phaseSecondsLeft,
    int? phaseSecondsTotal,
    int? pendingAnswerSecondsLeft,
    int? pendingAnswerSecondsTotal,
    Object? pendingAnswerPlayerId = _unset,
    List<String>? passedPlayerIds,
    List<String>? wrongAnswerPlayerIds,
    Object? lastCorrectAnswerPlayerId = _unset,
    bool? isMatchEnded,
    Object? winnerId = _unset,
    String? lastEvent,
  }) {
    return GameState(
      players: players ?? this.players,
      boardQuestions: boardQuestions ?? this.boardQuestions,
      currentQuestion: clearCurrentQuestion
          ? null
          : (currentQuestion ?? this.currentQuestion),
      phase: phase ?? this.phase,
      isPaused: isPaused ?? this.isPaused,
      round: round ?? this.round,
      currentChooserId: currentChooserId ?? this.currentChooserId,
      questionOwnerId: questionOwnerId ?? this.questionOwnerId,
      phaseSecondsLeft: phaseSecondsLeft ?? this.phaseSecondsLeft,
      phaseSecondsTotal: phaseSecondsTotal ?? this.phaseSecondsTotal,
      pendingAnswerSecondsLeft:
          pendingAnswerSecondsLeft ?? this.pendingAnswerSecondsLeft,
      pendingAnswerSecondsTotal:
          pendingAnswerSecondsTotal ?? this.pendingAnswerSecondsTotal,
      pendingAnswerPlayerId: identical(pendingAnswerPlayerId, _unset)
          ? this.pendingAnswerPlayerId
          : pendingAnswerPlayerId as String?,
      passedPlayerIds: passedPlayerIds ?? this.passedPlayerIds,
      wrongAnswerPlayerIds: wrongAnswerPlayerIds ?? this.wrongAnswerPlayerIds,
      lastCorrectAnswerPlayerId: identical(lastCorrectAnswerPlayerId, _unset)
          ? this.lastCorrectAnswerPlayerId
          : lastCorrectAnswerPlayerId as String?,
      isMatchEnded: isMatchEnded ?? this.isMatchEnded,
      winnerId:
          identical(winnerId, _unset) ? this.winnerId : winnerId as String?,
      lastEvent: lastEvent ?? this.lastEvent,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        players,
        boardQuestions,
        currentQuestion,
        phase,
        isPaused,
        round,
        currentChooserId,
        questionOwnerId,
        phaseSecondsLeft,
        phaseSecondsTotal,
        pendingAnswerSecondsLeft,
        pendingAnswerSecondsTotal,
        pendingAnswerPlayerId,
        passedPlayerIds,
        wrongAnswerPlayerIds,
        lastCorrectAnswerPlayerId,
        isMatchEnded,
        winnerId,
        lastEvent,
      ];
}

const Object _unset = Object();

List<Question> _buildRoundBoard() {
  const List<String> categories = <String>[
    'History',
    'Science',
    'Geography',
    'Movies',
    'Sports',
  ];
  const List<int> values = <int>[100, 200, 300, 400, 500];

  final List<Question> items = <Question>[];
  for (final String category in categories) {
    for (final int value in values) {
      final String id = '${category.toLowerCase().replaceAll(' ', '_')}-$value';
      items.add(
        Question(
          id: id,
          category: category,
          value: value,
          text:
              '[$category for $value] Name one key fact related to this topic.',
          answer: 'Sample answer for $category $value',
          used: false,
        ),
      );
    }
  }
  return items;
}

/// Simple scoring utility including final wager calculation.
class Scoring {
  static int applyAnswer({
    required int currentScore,
    required bool correct,
    required int value,
  }) {
    if (correct) {
      return currentScore + value;
    }
    return currentScore - value;
  }

  static int finalWagerResult({
    required int currentScore,
    required int wager,
    required bool correct,
  }) {
    final int safeWager = wager.clamp(0, currentScore.abs());
    if (correct) {
      return currentScore + safeWager;
    }
    return currentScore - safeWager;
  }
}
