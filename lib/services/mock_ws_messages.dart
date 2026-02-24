/// Message schemas for the mock WebSocket layer.
///
/// These map to JSON events a real backend would send.
///
/// - room_update:    { "type": "room_update", "players": [ { "id": "..", "name": "..", "score": 0 } ] }
/// - question:       { "type": "question", "id": "q1", "text": "...", "category": "History", "value": 200 }
/// - answer_result:  { "type": "answer_result", "correct": true, "delta": 200, "playerId": "p1" }
/// - score_update:   { "type": "score_update", "scores": [ { "playerId": "p1", "score": 400 } ] }
/// - match_end:      { "type": "match_end", "winnerId": "p1" }
///
/// In this local mock implementation we pass strongly-typed classes instead
/// of raw JSON to keep things easy to test.

abstract class WsMessage {}

class RoomUpdateMessage extends WsMessage {
  RoomUpdateMessage({required this.players});

  final List<WsPlayer> players;
}

class QuestionMessage extends WsMessage {
  QuestionMessage({
    required this.id,
    required this.text,
    required this.category,
    required this.value,
  });

  final String id;
  final String text;
  final String category;
  final int value;
}

class AnswerResultMessage extends WsMessage {
  AnswerResultMessage({
    required this.correct,
    required this.delta,
    required this.playerId,
  });

  final bool correct;
  final int delta;
  final String playerId;
}

class ScoreUpdateMessage extends WsMessage {
  ScoreUpdateMessage({required this.scores});

  final List<WsScore> scores;
}

class MatchEndMessage extends WsMessage {
  MatchEndMessage({required this.winnerId});

  final String winnerId;
}

class WsPlayer {
  WsPlayer({required this.id, required this.name, required this.score});

  final String id;
  final String name;
  final int score;
}

class WsScore {
  WsScore({required this.playerId, required this.score});

  final String playerId;
  final int score;
}
