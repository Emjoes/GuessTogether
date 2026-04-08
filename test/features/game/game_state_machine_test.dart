import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/features/game/domain/game_models.dart';
import 'package:guesstogether/features/game/domain/game_state_machine.dart';

void main() {
  const List<Player> players = <Player>[
    Player(id: 'p1', name: 'One', score: 0),
    Player(id: 'p2', name: 'Two', score: 0),
    Player(id: 'p3', name: 'Three', score: 0),
  ];

  test('initialMatch starts on board selection with server timers', () {
    final GameState state = GameStateMachine.initialMatch(players);

    expect(state.phase, GamePhase.boardSelection);
    expect(state.phaseSecondsLeft, GameStateMachine.boardPickSeconds);
    expect(state.currentChooserId, 'p1');
    expect(state.players, players);
    expect(state.round, 1);
    expect(state.boardQuestions, hasLength(2));
  });

  test('chooseQuestion enters short reveal phase before answer window', () {
    final GameState initial = GameStateMachine.initialMatch(players);
    final Question clue = initial.boardQuestions.first;

    final GameState selected = GameStateMachine.chooseQuestion(
      initial,
      questionId: clue.id,
      hostOverride: true,
    );
    final GameState answerWindow = GameStateMachine.tick(
      selected.copyWith(
        phaseSecondsLeft: 1,
        phaseSecondsTotal: GameStateMachine.questionRevealSeconds,
      ),
    );

    expect(selected.phase, GamePhase.questionReveal);
    expect(selected.currentQuestion?.id, clue.id);
    expect(answerWindow.phase, GamePhase.answerWindow);
    expect(answerWindow.phaseSecondsLeft, GameStateMachine.answerWindowSeconds);
  });

  test('acceptAnswer awards points and moves to answer reveal', () {
    final GameState initial = GameStateMachine.initialMatch(players);
    final Question clue = initial.boardQuestions.first;

    final GameState selected = GameStateMachine.chooseQuestion(
      initial,
      questionId: clue.id,
      hostOverride: true,
    );
    final GameState questionOpen = GameStateMachine.tick(
      selected.copyWith(
        phaseSecondsLeft: 1,
        phaseSecondsTotal: GameStateMachine.questionRevealSeconds,
      ),
    );
    final GameState answering =
        GameStateMachine.requestAnswer(questionOpen, 'p2');
    final GameState accepted = GameStateMachine.acceptAnswer(answering);

    expect(accepted.phase, GamePhase.answerReveal);
    expect(accepted.currentChooserId, 'p2');
    expect(accepted.lastCorrectAnswerPlayerId, 'p2');
    expect(
      accepted.players.firstWhere((Player player) => player.id == 'p2').score,
      clue.value,
    );
  });

  test('tick finishes last pending answer as wrong after timeout', () {
    final GameState initial = GameStateMachine.initialMatch(players);
    final Question clue = initial.boardQuestions.first;

    final GameState selected = GameStateMachine.chooseQuestion(
      initial,
      questionId: clue.id,
      hostOverride: true,
    );
    final GameState questionOpen = GameStateMachine.tick(
      selected.copyWith(
        phaseSecondsLeft: 1,
        phaseSecondsTotal: GameStateMachine.questionRevealSeconds,
      ),
    );
    final GameState answering =
        GameStateMachine.requestAnswer(questionOpen, 'p3').copyWith(
      pendingAnswerSecondsLeft: 1,
      pendingAnswerSecondsTotal: GameStateMachine.answerWindowSeconds,
    );

    final GameState timedOut = GameStateMachine.tick(answering);

    expect(timedOut.pendingAnswerPlayerId, isNull);
    expect(timedOut.wrongAnswerPlayerIds, contains('p3'));
    expect(timedOut.phase, GamePhase.answerWindow);
    expect(
      timedOut.players.firstWhere((Player player) => player.id == 'p3').score,
      -clue.value,
    );
  });

  test('skipQuestion returns to board selection and clears active clue', () {
    final List<Question> boardQuestions = <Question>[
      const Question(
        id: 'r1_q1',
        text: 'Round 1 clue',
        answer: 'A1',
        category: 'Theme 1',
        value: 100,
        used: true,
        round: 1,
      ),
      const Question(
        id: 'r1_q2',
        text: 'Round 1 clue 2',
        answer: 'A2',
        category: 'Theme 1',
        value: 200,
        used: false,
        round: 1,
      ),
    ];
    final GameState state = GameState.initial(
      players: players,
      boardQuestions: boardQuestions,
    ).copyWith(
      currentQuestion: boardQuestions.first,
      phase: GamePhase.questionReveal,
      phaseSecondsLeft: 2,
      phaseSecondsTotal: 2,
    );

    final GameState skipped = GameStateMachine.skipQuestion(state);

    expect(skipped.phase, GamePhase.boardSelection);
    expect(skipped.currentQuestion, isNull);
    expect(skipped.phaseSecondsLeft, GameStateMachine.boardPickSeconds);
  });

  test('skipRound moves directly to the next round', () {
    final List<Question> boardQuestions = <Question>[
      const Question(
        id: 'r1_q1',
        text: 'Round 1 clue',
        answer: 'A1',
        category: 'Theme 1',
        value: 100,
        used: false,
        round: 1,
      ),
      const Question(
        id: 'r1_q2',
        text: 'Round 1 clue 2',
        answer: 'A2',
        category: 'Theme 2',
        value: 200,
        used: false,
        round: 1,
      ),
      const Question(
        id: 'r2_q1',
        text: 'Round 2 clue',
        answer: 'B1',
        category: 'Theme 3',
        value: 400,
        used: false,
        round: 2,
      ),
    ];
    final GameState state = GameState.initial(
      players: players,
      boardQuestions: boardQuestions,
    ).copyWith(
      phase: GamePhase.boardSelection,
      phaseSecondsLeft: GameStateMachine.boardPickSeconds,
      phaseSecondsTotal: GameStateMachine.boardPickSeconds,
    );

    final GameState skipped = GameStateMachine.skipRound(state);

    expect(skipped.phase, GamePhase.boardSelection);
    expect(skipped.round, 2);
    expect(
      skipped.boardQuestions
          .where((Question question) => question.round == 1)
          .every((Question question) => question.used),
      isTrue,
    );
  });

  test('match moves to next round when current round board is exhausted', () {
    final List<Question> boardQuestions = <Question>[
      const Question(
        id: 'r1_q1',
        text: 'Round 1 clue',
        answer: 'A1',
        category: 'Theme 1',
        value: 100,
        used: false,
        round: 1,
      ),
      const Question(
        id: 'r2_q1',
        text: 'Round 2 clue',
        answer: 'A2',
        category: 'Theme 2',
        value: 200,
        used: false,
        round: 2,
      ),
    ];
    final GameState initial = GameStateMachine.initialMatch(
      players,
      boardQuestions: boardQuestions,
    );

    final GameState selected = GameStateMachine.chooseQuestion(
      initial,
      questionId: 'r1_q1',
      hostOverride: true,
    );
    final GameState questionOpen = GameStateMachine.tick(
      selected.copyWith(
        phaseSecondsLeft: 1,
        phaseSecondsTotal: GameStateMachine.questionRevealSeconds,
      ),
    );
    final GameState answering =
        GameStateMachine.requestAnswer(questionOpen, 'p2');
    final GameState accepted =
        GameStateMachine.acceptAnswer(answering).copyWith(
      phaseSecondsLeft: 1,
      phaseSecondsTotal: GameStateMachine.answerRevealSeconds,
    );

    final GameState nextRound = GameStateMachine.tick(accepted);

    expect(nextRound.phase, GamePhase.boardSelection);
    expect(nextRound.round, 2);
    expect(nextRound.currentQuestion, isNull);
    expect(nextRound.lastEvent, 'Round 2 begins.');
  });
}
