import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/features/game/domain/game_models.dart';
import 'package:guesstogether/features/game/providers/game_providers.dart';

void main() {
  test('GameController starts match and opens board selection', () async {
    final GameController controller = GameController();
    addTearDown(controller.dispose);

    await controller.startMatch();

    expect(controller.state.phase, GamePhase.boardSelection);
    expect(controller.state.phaseSecondsLeft, greaterThan(0));
    expect(controller.state.isMatchEnded, false);
  });

  test('Host can accept pending answer and add points', () async {
    final GameController controller = GameController();
    addTearDown(controller.dispose);

    await controller.startMatch();
    final Question clue = controller.state.boardQuestions.first;
    controller.chooseQuestion(clue.id, hostOverride: true);

    // Wait until question reveal phase transitions to answer window.
    await Future<void>.delayed(const Duration(seconds: 4));

    controller.requestAnswer('p1');
    controller.hostAcceptAnswer();

    final Player p1 = controller.state.players.firstWhere((p) => p.id == 'p1');
    expect(p1.score, clue.value);
    expect(controller.state.currentChooserId, 'p1');
    expect(controller.state.phase, GamePhase.answerReveal);
  });

  test('Host can reject answer and subtract points', () async {
    final GameController controller = GameController();
    addTearDown(controller.dispose);

    await controller.startMatch();
    final Question clue = controller.state.boardQuestions.first;
    controller.chooseQuestion(clue.id, hostOverride: true);
    await Future<void>.delayed(const Duration(seconds: 4));

    controller.requestAnswer('p1');
    controller.hostRejectAnswer();

    final Player p1 = controller.state.players.firstWhere((p) => p.id == 'p1');
    expect(p1.score, -clue.value);
    expect(controller.state.wrongAnswerPlayerIds.contains('p1'), true);
  });

  test('Any player can claim answer during answer window', () async {
    final GameController controller = GameController();
    addTearDown(controller.dispose);

    await controller.startMatch();
    final Question clue = controller.state.boardQuestions.first;
    controller.chooseQuestion(clue.id, hostOverride: true);

    controller.requestAnswer('p3');

    expect(controller.state.pendingAnswerPlayerId, 'p3');
    expect(controller.state.phase, GamePhase.answerWindow);
  });

  test('Correct answer transfers chooser to answering player', () async {
    final GameController controller = GameController();
    addTearDown(controller.dispose);

    await controller.startMatch();
    final Question clue = controller.state.boardQuestions.first;
    controller.chooseQuestion(clue.id, hostOverride: true);

    controller.requestAnswer('p3');
    controller.hostAcceptAnswer();

    final Player p3 = controller.state.players.firstWhere((p) => p.id == 'p3');
    expect(p3.score, clue.value);
    expect(controller.state.currentChooserId, 'p3');
    expect(controller.state.lastCorrectAnswerPlayerId, 'p3');
    expect(controller.state.phase, GamePhase.answerReveal);
  });

  test('Passed and wrong markers are cleared after answer reveal ends',
      () async {
    final GameController controller = GameController();
    addTearDown(controller.dispose);

    await controller.startMatch();
    final Question clue = controller.state.boardQuestions.first;
    controller.chooseQuestion(clue.id, hostOverride: true);

    controller.state = controller.state.copyWith(
      passedPlayerIds: const <String>['p2'],
      wrongAnswerPlayerIds: const <String>['p4'],
    );

    controller.requestAnswer('p3');
    controller.hostAcceptAnswer();

    expect(controller.state.phase, GamePhase.answerReveal);
    expect(controller.state.passedPlayerIds, const <String>['p2']);
    expect(controller.state.wrongAnswerPlayerIds, const <String>['p4']);
    expect(controller.state.lastCorrectAnswerPlayerId, 'p3');

    controller.state = controller.state.copyWith(
      phaseSecondsLeft: 0,
      phaseSecondsTotal: 3,
    );
    await Future<void>.delayed(const Duration(milliseconds: 1600));

    expect(controller.state.phase, GamePhase.boardSelection);
    expect(controller.state.passedPlayerIds, isEmpty);
    expect(controller.state.wrongAnswerPlayerIds, isEmpty);
    expect(controller.state.lastCorrectAnswerPlayerId, isNull);
  });

  test('Request answer resets answer timer to full duration', () async {
    final GameController controller = GameController();
    addTearDown(controller.dispose);

    await controller.startMatch();
    final Question clue = controller.state.boardQuestions.first;
    controller.chooseQuestion(clue.id, hostOverride: true);

    controller.state = controller.state.copyWith(
      phaseSecondsLeft: 4,
      phaseSecondsTotal: 12,
    );
    controller.requestAnswer('p2');

    expect(controller.state.pendingAnswerPlayerId, 'p2');
    expect(controller.state.phaseSecondsLeft, 4);
    expect(controller.state.phaseSecondsTotal, 12);
    expect(controller.state.pendingAnswerSecondsLeft, 12);
    expect(controller.state.pendingAnswerSecondsTotal, 12);
  });

  test('Question timer is paused while player is answering', () async {
    final GameController controller = GameController();
    addTearDown(controller.dispose);

    await controller.startMatch();
    final Question clue = controller.state.boardQuestions.first;
    controller.chooseQuestion(clue.id, hostOverride: true);

    controller.state = controller.state.copyWith(
      phaseSecondsLeft: 7,
      phaseSecondsTotal: 12,
    );
    controller.requestAnswer('p2');
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    expect(controller.state.phaseSecondsLeft, 7);
    expect(controller.state.pendingAnswerSecondsLeft, 11);
  });

  test('Pending answer timeout counts as wrong answer automatically', () async {
    final GameController controller = GameController();
    addTearDown(controller.dispose);

    await controller.startMatch();
    final Question clue = controller.state.boardQuestions.first;
    controller.chooseQuestion(clue.id, hostOverride: true);

    controller.state = controller.state.copyWith(
      pendingAnswerPlayerId: 'p2',
      phaseSecondsLeft: 5,
      phaseSecondsTotal: 12,
      pendingAnswerSecondsLeft: 0,
      pendingAnswerSecondsTotal: 12,
      wrongAnswerPlayerIds: const <String>[],
      passedPlayerIds: const <String>[],
    );

    await Future<void>.delayed(const Duration(milliseconds: 1600));

    final Player p2 = controller.state.players.firstWhere((p) => p.id == 'p2');
    expect(p2.score, -clue.value);
    expect(controller.state.wrongAnswerPlayerIds.contains('p2'), true);
    expect(controller.state.pendingAnswerPlayerId, isNull);
    expect(controller.state.pendingAnswerSecondsLeft, 0);
    expect(controller.state.phase, GamePhase.answerWindow);
  });

  test('Last available player pass is preserved during answer reveal',
      () async {
    final GameController controller = GameController();
    addTearDown(controller.dispose);

    await controller.startMatch();
    final Question clue = controller.state.boardQuestions.first;
    controller.chooseQuestion(clue.id, hostOverride: true);

    controller.state = controller.state.copyWith(
      phase: GamePhase.answerWindow,
      phaseSecondsLeft: 8,
      phaseSecondsTotal: 12,
      pendingAnswerPlayerId: null,
      passedPlayerIds: const <String>['p1', 'p2', 'p3'],
      wrongAnswerPlayerIds: const <String>[],
    );

    controller.passQuestion('p4');

    expect(controller.state.phase, GamePhase.answerReveal);
    expect(
      controller.state.passedPlayerIds,
      containsAll(const <String>['p1', 'p2', 'p3', 'p4']),
    );
  });
}
