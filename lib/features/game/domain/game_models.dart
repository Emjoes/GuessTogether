import 'package:equatable/equatable.dart';

enum GamePhase {
  waitingForHost,
  boardSelection,
  catInBagTransfer,
  auctionBidding,
  questionReveal,
  answerWindow,
  answerReveal,
  roundAnnouncement,
  paused,
  finished,
}

enum QuestionType { normal, catInBag, auction }

QuestionType _parseQuestionType(String? value) {
  return QuestionType.values.firstWhere(
    (QuestionType candidate) => candidate.name == value,
    orElse: () => QuestionType.normal,
  );
}

enum QuestionMediaType { image, audio, video }

QuestionMediaType _parseQuestionMediaType(String value) {
  return QuestionMediaType.values.firstWhere(
    (QuestionMediaType candidate) => candidate.name == value,
    orElse: () => QuestionMediaType.image,
  );
}

class QuestionMedia extends Equatable {
  const QuestionMedia({
    required this.type,
    required this.path,
    this.label = '',
    this.isBackground = false,
  });

  final QuestionMediaType type;
  final String path;
  final String label;
  final bool isBackground;

  QuestionMedia copyWith({
    QuestionMediaType? type,
    String? path,
    String? label,
    bool? isBackground,
  }) {
    return QuestionMedia(
      type: type ?? this.type,
      path: path ?? this.path,
      label: label ?? this.label,
      isBackground: isBackground ?? this.isBackground,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.name,
        'path': path,
        'label': label,
        'isBackground': isBackground,
      };

  factory QuestionMedia.fromJson(Map<String, dynamic> json) {
    return QuestionMedia(
      type: _parseQuestionMediaType(json['type'] as String? ?? 'image'),
      path: json['path'] as String? ?? '',
      label: json['label'] as String? ?? '',
      isBackground: json['isBackground'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => <Object?>[type, path, label, isBackground];
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
    this.questionMedia = const <QuestionMedia>[],
    this.answerMedia = const <QuestionMedia>[],
    this.round = 1,
    this.type = QuestionType.normal,
  });

  final String id;
  final String text;
  final String answer;
  final String category;
  final int value;
  final bool used;
  final List<QuestionMedia> questionMedia;
  final List<QuestionMedia> answerMedia;
  final int round;
  final QuestionType type;

  Question copyWith({
    String? text,
    String? answer,
    String? category,
    int? value,
    bool? used,
    List<QuestionMedia>? questionMedia,
    List<QuestionMedia>? answerMedia,
    int? round,
    QuestionType? type,
  }) {
    return Question(
      id: id,
      text: text ?? this.text,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      value: value ?? this.value,
      used: used ?? this.used,
      questionMedia: questionMedia ?? this.questionMedia,
      answerMedia: answerMedia ?? this.answerMedia,
      round: round ?? this.round,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'text': text,
        'answer': answer,
        'category': category,
        'value': value,
        'used': used,
        'questionMedia':
            questionMedia.map((QuestionMedia item) => item.toJson()).toList(),
        'answerMedia':
            answerMedia.map((QuestionMedia item) => item.toJson()).toList(),
        'round': round,
        'type': type.name,
      };

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      category: json['category'] as String? ?? '',
      value: (json['value'] as num?)?.toInt() ?? 0,
      used: json['used'] as bool? ?? false,
      questionMedia: ((json['questionMedia'] as List<dynamic>?) ?? <dynamic>[])
          .whereType<Map>()
          .map(
            (Map item) => QuestionMedia.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      answerMedia: ((json['answerMedia'] as List<dynamic>?) ?? <dynamic>[])
          .whereType<Map>()
          .map(
            (Map item) => QuestionMedia.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      round: (json['round'] as num?)?.toInt() ?? 1,
      type: _parseQuestionType(json['type'] as String?),
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
        questionMedia,
        answerMedia,
        round,
        type,
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
    this.auctionBids = const <String, int>{},
    this.auctionPassedPlayerIds = const <String>[],
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
      auctionBids: const <String, int>{},
      auctionPassedPlayerIds: const <String>[],
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
  final Map<String, int> auctionBids;
  final List<String> auctionPassedPlayerIds;

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
    Map<String, int>? auctionBids,
    List<String>? auctionPassedPlayerIds,
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
      auctionBids: auctionBids ?? this.auctionBids,
      auctionPassedPlayerIds:
          auctionPassedPlayerIds ?? this.auctionPassedPlayerIds,
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
        'auctionBids': auctionBids,
        'auctionPassedPlayerIds': auctionPassedPlayerIds,
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
      auctionBids: (json['auctionBids'] as Map<String, dynamic>? ?? <String, dynamic>{})
          .map((String k, dynamic v) => MapEntry<String, int>(k, (v as num?)?.toInt() ?? 0)),
      auctionPassedPlayerIds:
          ((json['auctionPassedPlayerIds'] as List<dynamic>?) ?? <dynamic>[])
              .map((dynamic item) => item as String)
              .toList(),
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
        auctionBids,
        auctionPassedPlayerIds,
      ];
}

const Object _unset = Object();

List<Question> _buildRoundBoard() {
  const List<(String, int, QuestionType)> defs =
      <(String, int, QuestionType)>[
    ('Quick Test', 100, QuestionType.normal),
    ('Quick Test', 200, QuestionType.catInBag),
    ('Quick Test', 300, QuestionType.auction),
    ('Quick Test', 400, QuestionType.normal),
    ('Quick Test', 500, QuestionType.normal),
    ('Science', 100, QuestionType.normal),
    ('Science', 200, QuestionType.normal),
    ('Science', 300, QuestionType.catInBag),
    ('Science', 400, QuestionType.auction),
    ('Science', 500, QuestionType.normal),
  ];

  return defs.indexed
      .map(
        ((int, (String, int, QuestionType)) entry) {
          final int i = entry.$1;
          final (String cat, int value, QuestionType type) = entry.$2;
          return Question(
            id: 'debug_q${i + 1}',
            category: cat,
            value: value,
            text: '[$cat for $value] Debug question ${i + 1}.',
            answer: 'Answer ${i + 1}',
            used: false,
            type: type,
          );
        },
      )
      .toList(growable: false);
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
