import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/features/game/domain/game_models.dart';
import 'package:guesstogether/server/question_pack_builder.dart';

Map<String, dynamic> _loadEnglishPackJson() {
  final String raw = File('backend_packages/general_quiz_pack_en.json')
      .readAsStringSync(encoding: utf8);
  return jsonDecode(raw) as Map<String, dynamic>;
}

Map<String, dynamic> _loadRussianPackJson() {
  final String raw = File('backend_packages/general_quiz_pack_ru.json')
      .readAsStringSync(encoding: utf8);
  return jsonDecode(raw) as Map<String, dynamic>;
}

void main() {
  test('english standard pack contains 15 themes and 25 questions per theme',
      () {
    final Map<String, dynamic> json = _loadEnglishPackJson();
    final List<dynamic> themes = json['themes'] as List<dynamic>;

    expect(themes, hasLength(15));

    for (final dynamic themeEntry in themes) {
      final Map<String, dynamic> theme = themeEntry as Map<String, dynamic>;
      final List<dynamic> questions = theme['questions'] as List<dynamic>;
      expect(questions, hasLength(25));

      final Map<int, int> countsByDifficulty = <int, int>{};
      final Set<String> ids = <String>{};
      final Set<String> texts = <String>{};
      final Set<String> answers = <String>{};
      for (final dynamic questionEntry in questions) {
        final Map<String, dynamic> question =
            questionEntry as Map<String, dynamic>;
        final int difficulty = (question['difficulty'] as num).toInt();
        ids.add(question['id'] as String);
        texts.add((question['text'] as String).trim());
        answers.add((question['answer'] as String).trim());
        countsByDifficulty.update(
          difficulty,
          (int value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      expect(ids, hasLength(25));
      expect(texts, hasLength(25));
      expect(answers, hasLength(25));

      expect(
        countsByDifficulty,
        <int, int>{1: 5, 2: 5, 3: 5, 4: 5, 5: 5},
      );
    }
  });

  test('builder assembles 3 rounds with derived values and unique themes', () {
    final Map<String, dynamic> json = _loadEnglishPackJson();

    final List<Question> questions = buildQuestionSetFromPackageJson(
      json,
      rounds: 3,
      random: Random(7),
    );

    expect(questions, hasLength(75));
    expect(
      questions.map((Question question) => question.id).toSet(),
      hasLength(75),
    );
    expect(
      questions.map((Question question) => question.category).toSet(),
      hasLength(15),
    );

    for (int round = 1; round <= 3; round++) {
      final List<Question> roundQuestions = questions
          .where((Question question) => question.round == round)
          .toList(growable: false);
      expect(roundQuestions, hasLength(25));

      final Set<String> categories =
          roundQuestions.map((Question question) => question.category).toSet();
      expect(categories, hasLength(5));

      for (final String category in categories) {
        final List<Question> categoryQuestions = roundQuestions
            .where((Question question) => question.category == category)
            .toList(growable: false);
        expect(categoryQuestions, hasLength(5));

        final List<int> values = categoryQuestions
            .map((Question question) => question.value)
            .toList()
          ..sort();
        expect(
          values,
          <int>[
            100 * round,
            200 * round,
            300 * round,
            400 * round,
            500 * round,
          ],
        );
      }
    }
  });

  test('localized packs keep identical theme and question ids', () {
    final Map<String, dynamic> english = _loadEnglishPackJson();
    final Map<String, dynamic> russian = _loadRussianPackJson();

    final List<dynamic> englishThemes = english['themes'] as List<dynamic>;
    final List<dynamic> russianThemes = russian['themes'] as List<dynamic>;
    expect(russianThemes, hasLength(englishThemes.length));

    for (int themeIndex = 0; themeIndex < englishThemes.length; themeIndex++) {
      final Map<String, dynamic> englishTheme =
          englishThemes[themeIndex] as Map<String, dynamic>;
      final Map<String, dynamic> russianTheme =
          russianThemes[themeIndex] as Map<String, dynamic>;
      expect(russianTheme['id'], englishTheme['id']);

      final List<dynamic> englishQuestions =
          englishTheme['questions'] as List<dynamic>;
      final List<dynamic> russianQuestions =
          russianTheme['questions'] as List<dynamic>;
      expect(russianQuestions, hasLength(englishQuestions.length));

      for (int questionIndex = 0;
          questionIndex < englishQuestions.length;
          questionIndex++) {
        final Map<String, dynamic> englishQuestion =
            englishQuestions[questionIndex] as Map<String, dynamic>;
        final Map<String, dynamic> russianQuestion =
            russianQuestions[questionIndex] as Map<String, dynamic>;
        expect(russianQuestion['id'], englishQuestion['id']);
        expect(russianQuestion['difficulty'], englishQuestion['difficulty']);
      }
    }
  });

  test('localized packs keep 25 unique texts and answers per theme', () {
    for (final Map<String, dynamic> json in <Map<String, dynamic>>[
      _loadEnglishPackJson(),
      _loadRussianPackJson(),
    ]) {
      final List<dynamic> themes = json['themes'] as List<dynamic>;
      for (final dynamic themeEntry in themes) {
        final Map<String, dynamic> theme = themeEntry as Map<String, dynamic>;
        final List<dynamic> questions = theme['questions'] as List<dynamic>;
        final Set<String> texts = questions.map((dynamic questionEntry) {
          final Map<String, dynamic> question =
              questionEntry as Map<String, dynamic>;
          return (question['text'] as String).trim();
        }).toSet();
        final Set<String> answers = questions.map((dynamic questionEntry) {
          final Map<String, dynamic> question =
              questionEntry as Map<String, dynamic>;
          return (question['answer'] as String).trim();
        }).toSet();
        expect(texts, hasLength(25), reason: 'theme=${theme['id']}');
        expect(answers, hasLength(25), reason: 'theme=${theme['id']}');
      }
    }
  });

  test('localized packs build the same question ids for the same seed', () {
    final Map<String, dynamic> english = _loadEnglishPackJson();
    final Map<String, dynamic> russian = _loadRussianPackJson();

    final List<Question> englishQuestions = buildQuestionSetFromPackageJson(
      english,
      rounds: 3,
      random: Random(7),
    );
    final List<Question> russianQuestions = buildQuestionSetFromPackageJson(
      russian,
      rounds: 3,
      random: Random(7),
    );

    expect(russianQuestions, hasLength(englishQuestions.length));
    expect(
      russianQuestions.map((Question question) => question.id).toList(),
      englishQuestions.map((Question question) => question.id).toList(),
    );
    expect(
      russianQuestions.map((Question question) => question.round).toList(),
      englishQuestions.map((Question question) => question.round).toList(),
    );
    expect(
      russianQuestions.map((Question question) => question.value).toList(),
      englishQuestions.map((Question question) => question.value).toList(),
    );
  });

  test('game state localization preserves ids while swapping visible text', () {
    final Map<String, dynamic> english = _loadEnglishPackJson();
    final Map<String, dynamic> russian = _loadRussianPackJson();
    final List<Question> englishQuestions = buildQuestionSetFromPackageJson(
      english,
      rounds: 1,
      random: Random(3),
    );

    final GameState englishState = GameState.initial(
      players: const <Player>[
        Player(id: 'p1', name: 'One', score: 0),
        Player(id: 'p2', name: 'Two', score: 0),
      ],
      boardQuestions: englishQuestions,
    ).copyWith(
      currentQuestion: englishQuestions.first,
      phase: GamePhase.questionReveal,
    );

    final GameState russianState =
        localizeGameStateFromPackageJson(englishState, russian);

    expect(
      russianState.boardQuestions
          .map((Question question) => question.id)
          .toList(),
      englishState.boardQuestions
          .map((Question question) => question.id)
          .toList(),
    );
    expect(russianState.currentQuestion?.id, englishState.currentQuestion?.id);
    expect(
      russianState.currentQuestion?.text,
      isNot(englishState.currentQuestion?.text),
    );
    expect(
      russianState.currentQuestion?.category,
      isNot(englishState.currentQuestion?.category),
    );
  });
}
