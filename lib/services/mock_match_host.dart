import 'dart:async';

import 'package:guesstogether/services/mock_ws_messages.dart';

class MockMatchTiming {
  const MockMatchTiming({
    required this.beforeQuestion,
    required this.beforeAnswer,
    required this.afterMatch,
  });

  final Duration beforeQuestion;
  final Duration beforeAnswer;
  final Duration afterMatch;

  static const MockMatchTiming defaults = MockMatchTiming(
    beforeQuestion: Duration(seconds: 1),
    beforeAnswer: Duration(seconds: 3),
    afterMatch: Duration(seconds: 1),
  );
}

/// Local in-process mock match host that simulates a short match.
///
/// The host exposes a stream of [WsMessage] events which a WebSocket-like
/// adapter can consume.
class MockMatchHost {
  MockMatchHost({
    this.timing = MockMatchTiming.defaults,
    List<QuestionMessage>? questions,
  }) : _questions = questions ?? _defaultQuestions;

  final MockMatchTiming timing;
  final List<QuestionMessage> _questions;

  final StreamController<WsMessage> _controller =
      StreamController<WsMessage>.broadcast();

  Stream<WsMessage> get stream => _controller.stream;

  Future<void> startScriptedMatch() async {
    // Initial players in room.
    _controller.add(
      RoomUpdateMessage(
        players: <WsPlayer>[
          WsPlayer(id: 'p1', name: 'You', score: 0),
          WsPlayer(id: 'p2', name: 'QuizBot', score: 0),
          WsPlayer(id: 'p3', name: 'Brainiac', score: 0),
        ],
      ),
    );

    for (final QuestionMessage q in _questions) {
      await Future<void>.delayed(timing.beforeQuestion);
      _controller.add(q);
      // Simulate an answer result a bit later.
      await Future<void>.delayed(timing.beforeAnswer);
      _controller.add(
        AnswerResultMessage(
          correct: true,
          delta: q.value,
          playerId: 'p1',
        ),
      );
      _controller.add(
        ScoreUpdateMessage(
          scores: <WsScore>[
            WsScore(playerId: 'p1', score: q.value),
            WsScore(playerId: 'p2', score: q.value ~/ 2),
            WsScore(playerId: 'p3', score: q.value ~/ 2),
          ],
        ),
      );
    }

    await Future<void>.delayed(timing.afterMatch);
    _controller.add(MatchEndMessage(winnerId: 'p1'));
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

final List<QuestionMessage> _defaultQuestions = <QuestionMessage>[
  QuestionMessage(
    id: 'q1',
    text: 'In which year did the first man land on the Moon?',
    category: 'Space',
    value: 200,
  ),
  QuestionMessage(
    id: 'q2',
    text: 'Which element has the chemical symbol O?',
    category: 'Science',
    value: 200,
  ),
  QuestionMessage(
    id: 'q3',
    text: 'What is the capital of Japan?',
    category: 'Geography',
    value: 400,
  ),
];
