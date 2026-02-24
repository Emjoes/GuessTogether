import 'package:flutter_test/flutter_test.dart';
import 'package:guesstogether/features/game/domain/game_models.dart';

void main() {
  group('Scoring.applyAnswer', () {
    test('adds value on correct', () {
      expect(
        Scoring.applyAnswer(currentScore: 100, correct: true, value: 200),
        300,
      );
    });

    test('subtracts value on incorrect', () {
      expect(
        Scoring.applyAnswer(currentScore: 100, correct: false, value: 200),
        -100,
      );
    });

    test('handles zero value', () {
      expect(
        Scoring.applyAnswer(currentScore: 100, correct: false, value: 0),
        100,
      );
    });
  });

  group('Scoring.finalWagerResult', () {
    test('clamps wager to absolute score', () {
      expect(
        Scoring.finalWagerResult(currentScore: 300, wager: 999, correct: true),
        600,
      );
    });

    test('subtracts wager on incorrect', () {
      expect(
        Scoring.finalWagerResult(currentScore: 300, wager: 200, correct: false),
        100,
      );
    });
  });
}

