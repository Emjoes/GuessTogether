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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'score': score,
      };

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
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
    this.round = 1,
  });

  final String id;
  final String text;
  final String answer;
  final String category;
  final int value;
  final bool used;
  final int round;

  Question copyWith({
    String? text,
    String? answer,
    String? category,
    int? value,
    bool? used,
    int? round,
  }) {
    return Question(
      id: id,
      text: text ?? this.text,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      value: value ?? this.value,
      used: used ?? this.used,
      round: round ?? this.round,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'text': text,
        'answer': answer,
        'category': category,
        'value': value,
        'used': used,
        'round': round,
      };

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      category: json['category'] as String? ?? '',
      value: (json['value'] as num?)?.toInt() ?? 0,
      used: json['used'] as bool? ?? false,
      round: (json['round'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        text,
        answer,
        category,
        value,
        used,
        round,
      ];
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

  factory GameState.initial({
    List<Player>? players,
    List<Question>? boardQuestions,
  }) {
    final List<Player> safePlayers = (players == null || players.isEmpty)
        ? const <Player>[
            Player(id: 'p1', name: 'Serge', score: 0),
            Player(id: 'p2', name: 'Ivy', score: 0),
            Player(id: 'p3', name: 'Max', score: 0),
            Player(id: 'p4', name: 'Nova', score: 0),
          ]
        : players;
    return GameState(
      players: safePlayers,
      boardQuestions: boardQuestions ?? _buildRoundBoard(),
      currentQuestion: null,
      phase: GamePhase.waitingForHost,
      isPaused: false,
      round: 1,
      currentChooserId: safePlayers.first.id,
      questionOwnerId: safePlayers.first.id,
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
  Iterable<Question> get roundBoardQuestions =>
      boardQuestions.where((Question question) => question.round == round);
  bool get hasBoardQuestionsLeft =>
      roundBoardQuestions.any((Question question) => !question.used);
  int? get nextRoundNumber {
    final List<int> rounds = boardQuestions
        .map((Question question) => question.round)
        .where((int questionRound) => questionRound > round)
        .toSet()
        .toList()
      ..sort();
    return rounds.isEmpty ? null : rounds.first;
  }
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'players': players.map((Player player) => player.toJson()).toList(),
        'boardQuestions': boardQuestions
            .map((Question question) => question.toJson())
            .toList(),
        'currentQuestion': currentQuestion?.toJson(),
        'phase': phase.name,
        'isPaused': isPaused,
        'round': round,
        'currentChooserId': currentChooserId,
        'questionOwnerId': questionOwnerId,
        'phaseSecondsLeft': phaseSecondsLeft,
        'phaseSecondsTotal': phaseSecondsTotal,
        'pendingAnswerSecondsLeft': pendingAnswerSecondsLeft,
        'pendingAnswerSecondsTotal': pendingAnswerSecondsTotal,
        'pendingAnswerPlayerId': pendingAnswerPlayerId,
        'passedPlayerIds': passedPlayerIds,
        'wrongAnswerPlayerIds': wrongAnswerPlayerIds,
        'lastCorrectAnswerPlayerId': lastCorrectAnswerPlayerId,
        'isMatchEnded': isMatchEnded,
        'winnerId': winnerId,
        'lastEvent': lastEvent,
      };

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      players: ((json['players'] as List<dynamic>? ?? <dynamic>[]))
          .map((dynamic item) => Player.fromJson(item as Map<String, dynamic>))
          .toList(),
      boardQuestions:
          ((json['boardQuestions'] as List<dynamic>? ?? <dynamic>[]))
              .map(
                (dynamic item) =>
                    Question.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      currentQuestion: json['currentQuestion'] is Map<String, dynamic>
          ? Question.fromJson(json['currentQuestion'] as Map<String, dynamic>)
          : null,
      phase: GamePhase.values.firstWhere(
        (GamePhase value) => value.name == (json['phase'] as String? ?? ''),
        orElse: () => GamePhase.waitingForHost,
      ),
      isPaused: json['isPaused'] as bool? ?? false,
      round: (json['round'] as num?)?.toInt() ?? 1,
      currentChooserId: json['currentChooserId'] as String? ?? '',
      questionOwnerId: json['questionOwnerId'] as String? ?? '',
      phaseSecondsLeft: (json['phaseSecondsLeft'] as num?)?.toInt() ?? 0,
      phaseSecondsTotal: (json['phaseSecondsTotal'] as num?)?.toInt() ?? 0,
      pendingAnswerSecondsLeft:
          (json['pendingAnswerSecondsLeft'] as num?)?.toInt() ?? 0,
      pendingAnswerSecondsTotal:
          (json['pendingAnswerSecondsTotal'] as num?)?.toInt() ?? 0,
      pendingAnswerPlayerId: json['pendingAnswerPlayerId'] as String?,
      passedPlayerIds:
          ((json['passedPlayerIds'] as List<dynamic>? ?? <dynamic>[]))
              .map((dynamic item) => item as String)
              .toList(),
      wrongAnswerPlayerIds:
          ((json['wrongAnswerPlayerIds'] as List<dynamic>? ?? <dynamic>[]))
              .map((dynamic item) => item as String)
              .toList(),
      lastCorrectAnswerPlayerId: json['lastCorrectAnswerPlayerId'] as String?,
      isMatchEnded: json['isMatchEnded'] as bool? ?? false,
      winnerId: json['winnerId'] as String?,
      lastEvent: json['lastEvent'] as String? ?? '',
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
  const String category = 'Quick Test';
  const List<int> values = <int>[100, 200];

  final List<Question> items = <Question>[];
  for (final int value in values) {
    final String id = '${category.toLowerCase().replaceAll(' ', '_')}-$value';
    items.add(
      Question(
        id: id,
        category: category,
        value: value,
        text: '[$category for $value] Name one key fact related to this topic.',
        answer: 'Sample answer for $category $value',
        used: false,
      ),
    );
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
