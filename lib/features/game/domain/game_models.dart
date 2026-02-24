import 'package:equatable/equatable.dart';

class Player extends Equatable {
  const Player({
    required this.id,
    required this.name,
    required this.score,
  });

  final String id;
  final String name;
  final int score;

  Player copyWith({int? score}) {
    return Player(
      id: id,
      name: name,
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
    required this.category,
    required this.value,
  });

  final String id;
  final String text;
  final String category;
  final int value;

  @override
  List<Object?> get props => <Object?>[id, text, category, value];
}

class GameState extends Equatable {
  const GameState({
    required this.players,
    required this.boardQuestions,
    required this.currentQuestion,
    required this.remainingSeconds,
    required this.isAnswering,
    required this.isMatchEnded,
    required this.winnerId,
  });

  factory GameState.initial() {
    return const GameState(
      players: <Player>[],
      boardQuestions: <Question>[],
      currentQuestion: null,
      remainingSeconds: 0,
      isAnswering: false,
      isMatchEnded: false,
      winnerId: null,
    );
  }

  final List<Player> players;
  final List<Question> boardQuestions;
  final Question? currentQuestion;
  final int remainingSeconds;
  final bool isAnswering;
  final bool isMatchEnded;
  final String? winnerId;

  GameState copyWith({
    List<Player>? players,
    List<Question>? boardQuestions,
    Question? currentQuestion,
    bool clearCurrentQuestion = false,
    int? remainingSeconds,
    bool? isAnswering,
    bool? isMatchEnded,
    String? winnerId,
  }) {
    return GameState(
      players: players ?? this.players,
      boardQuestions: boardQuestions ?? this.boardQuestions,
      currentQuestion: clearCurrentQuestion
          ? null
          : (currentQuestion ?? this.currentQuestion),
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isAnswering: isAnswering ?? this.isAnswering,
      isMatchEnded: isMatchEnded ?? this.isMatchEnded,
      winnerId: winnerId ?? this.winnerId,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        players,
        boardQuestions,
        currentQuestion,
        remainingSeconds,
        isAnswering,
        isMatchEnded,
        winnerId,
      ];
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
    final safeWager = wager.clamp(0, currentScore.abs());
    if (correct) {
      return currentScore + safeWager;
    }
    return currentScore - safeWager;
  }
}
