import 'dart:math';

import 'package:guesstogether/features/game/domain/game_models.dart';

List<Question> loadQuestionsFromPackageJson(
  Map<String, dynamic> json, {
  required int rounds,
}) {
  final int effectiveRounds = rounds < 1 ? 1 : rounds;
  if (json['themes'] is List<dynamic>) {
    return _buildStructuredQuestionSet(
      _parseThemePools(json),
      rounds: effectiveRounds,
    );
  }
  return _buildLegacyQuestionSet(json, rounds: effectiveRounds);
}

List<Question> buildQuestionSetFromPackageJson(
  Map<String, dynamic> json, {
  required int rounds,
  required Random random,
}) {
  final int effectiveRounds = rounds < 1 ? 1 : rounds;
  if (json['themes'] is List<dynamic>) {
    return _buildStructuredQuestionSet(
      _parseThemePools(json),
      rounds: effectiveRounds,
      random: random,
    );
  }
  return _buildLegacyQuestionSet(json, rounds: effectiveRounds);
}

QuestionLocalizationCatalog buildQuestionLocalizationCatalogFromPackageJson(
  Map<String, dynamic> json,
) {
  if (json['themes'] is! List<dynamic>) {
    return _buildLegacyQuestionLocalizationCatalog(json);
  }
  final List<dynamic> themeEntries =
      json['themes'] as List<dynamic>? ?? <dynamic>[];
  final Map<String, _LocalizedQuestionContent> contentBySourceId =
      <String, _LocalizedQuestionContent>{};
  for (int themeIndex = 0; themeIndex < themeEntries.length; themeIndex++) {
    final Map<String, dynamic> themeJson =
        themeEntries[themeIndex] as Map<String, dynamic>;
    final String rawTitle = (themeJson['title'] as String? ?? '').trim();
    final String category =
        rawTitle.isEmpty ? 'Theme ${themeIndex + 1}' : rawTitle;
    final String rawThemeId = (themeJson['id'] as String? ?? '').trim();
    final String themeId =
        rawThemeId.isEmpty ? 'theme_${themeIndex + 1}' : rawThemeId;
    final List<dynamic> questionEntries =
        themeJson['questions'] as List<dynamic>? ?? <dynamic>[];
    for (int questionIndex = 0;
        questionIndex < questionEntries.length;
        questionIndex++) {
      final Map<String, dynamic> questionJson =
          questionEntries[questionIndex] as Map<String, dynamic>;
      final int difficulty = (questionJson['difficulty'] as num?)?.toInt() ?? 0;
      final String rawQuestionId = (questionJson['id'] as String? ?? '').trim();
      final String questionId = rawQuestionId.isEmpty
          ? difficulty >= 1 && difficulty <= 5
              ? '${themeId}_d${difficulty}_q${questionIndex + 1}'
              : '${themeId}_q${questionIndex + 1}'
          : rawQuestionId;
      contentBySourceId[questionId] = _LocalizedQuestionContent(
        text: (questionJson['text'] as String? ?? '').trim(),
        answer: (questionJson['answer'] as String? ?? '').trim(),
        category: category,
      );
    }
  }
  return QuestionLocalizationCatalog._(contentBySourceId);
}

QuestionLocalizationCatalog _buildLegacyQuestionLocalizationCatalog(
  Map<String, dynamic> json,
) {
  final Map<String, _LocalizedQuestionContent> contentBySourceId =
      <String, _LocalizedQuestionContent>{};
  final List<dynamic> roundEntries =
      json['rounds'] as List<dynamic>? ?? <dynamic>[];
  for (int roundIndex = 0; roundIndex < roundEntries.length; roundIndex++) {
    final Map<String, dynamic> roundJson =
        roundEntries[roundIndex] as Map<String, dynamic>;
    final List<dynamic> themes =
        roundJson['themes'] as List<dynamic>? ?? <dynamic>[];
    for (int themeIndex = 0; themeIndex < themes.length; themeIndex++) {
      final Map<String, dynamic> themeJson =
          themes[themeIndex] as Map<String, dynamic>;
      final String category = (themeJson['title'] as String? ?? '').trim();
      final List<dynamic> themeQuestions =
          themeJson['questions'] as List<dynamic>? ?? <dynamic>[];
      for (int questionIndex = 0;
          questionIndex < themeQuestions.length;
          questionIndex++) {
        final Map<String, dynamic> item =
            themeQuestions[questionIndex] as Map<String, dynamic>;
        final String rawQuestionId = (item['id'] as String? ?? '').trim();
        if (rawQuestionId.isEmpty) {
          continue;
        }
        contentBySourceId[rawQuestionId] = _LocalizedQuestionContent(
          text: (item['text'] as String? ?? '').trim(),
          answer: (item['answer'] as String? ?? '').trim(),
          category: category,
        );
      }
    }
  }
  return QuestionLocalizationCatalog._(contentBySourceId);
}

List<Question> localizeQuestionsFromPackageJson(
  Iterable<Question> questions,
  Map<String, dynamic> json,
) {
  return buildQuestionLocalizationCatalogFromPackageJson(json)
      .localizeQuestions(questions);
}

GameState localizeGameStateFromPackageJson(
  GameState state,
  Map<String, dynamic> json,
) {
  return buildQuestionLocalizationCatalogFromPackageJson(json)
      .localizeGameState(state);
}

List<Question> _buildLegacyQuestionSet(
  Map<String, dynamic> json, {
  required int rounds,
}) {
  final List<Question> questions = <Question>[];
  final List<dynamic> roundEntries =
      json['rounds'] as List<dynamic>? ?? <dynamic>[];
  for (int roundIndex = 0; roundIndex < roundEntries.length; roundIndex++) {
    final Map<String, dynamic> roundJson =
        roundEntries[roundIndex] as Map<String, dynamic>;
    final int roundNumber =
        (roundJson['round'] as num?)?.toInt() ?? (roundIndex + 1);
    if (roundNumber > rounds) {
      continue;
    }

    final List<dynamic> themes =
        roundJson['themes'] as List<dynamic>? ?? <dynamic>[];
    for (int themeIndex = 0; themeIndex < themes.length; themeIndex++) {
      final Map<String, dynamic> themeJson =
          themes[themeIndex] as Map<String, dynamic>;
      final String category = (themeJson['title'] as String? ?? '').trim();
      final List<dynamic> themeQuestions =
          themeJson['questions'] as List<dynamic>? ?? <dynamic>[];
      for (int questionIndex = 0;
          questionIndex < themeQuestions.length;
          questionIndex++) {
        final Map<String, dynamic> item =
            themeQuestions[questionIndex] as Map<String, dynamic>;
        final int value =
            (item['value'] as num?)?.toInt() ?? ((questionIndex + 1) * 100);
        final String id = (item['id'] as String? ?? '').trim().isEmpty
            ? 'r${roundNumber}_t${themeIndex + 1}_q${questionIndex + 1}'
            : (item['id'] as String).trim();
        questions.add(
          Question(
            id: id,
            text: item['text'] as String? ?? '',
            answer: item['answer'] as String? ?? '',
            category: category.isEmpty ? 'Theme ${themeIndex + 1}' : category,
            value: value,
            used: false,
            round: roundNumber,
          ),
        );
      }
    }
  }

  if (questions.isEmpty) {
    throw StateError('Question package does not contain playable questions.');
  }
  return questions;
}

List<_ThemePool> _parseThemePools(Map<String, dynamic> json) {
  final List<dynamic> themeEntries =
      json['themes'] as List<dynamic>? ?? <dynamic>[];
  final List<_ThemePool> themes = <_ThemePool>[];
  for (int themeIndex = 0; themeIndex < themeEntries.length; themeIndex++) {
    final Map<String, dynamic> themeJson =
        themeEntries[themeIndex] as Map<String, dynamic>;
    final String rawTitle = (themeJson['title'] as String? ?? '').trim();
    final String title =
        rawTitle.isEmpty ? 'Theme ${themeIndex + 1}' : rawTitle;
    final String rawId = (themeJson['id'] as String? ?? '').trim();
    final String themeId = rawId.isEmpty ? 'theme_${themeIndex + 1}' : rawId;
    final Map<int, List<_QuestionVariant>> variantsByDifficulty =
        <int, List<_QuestionVariant>>{};
    final List<dynamic> questionEntries =
        themeJson['questions'] as List<dynamic>? ?? <dynamic>[];
    for (int questionIndex = 0;
        questionIndex < questionEntries.length;
        questionIndex++) {
      final Map<String, dynamic> questionJson =
          questionEntries[questionIndex] as Map<String, dynamic>;
      final int difficulty = (questionJson['difficulty'] as num?)?.toInt() ?? 0;
      if (difficulty < 1 || difficulty > 5) {
        continue;
      }

      final String rawQuestionId = (questionJson['id'] as String? ?? '').trim();
      final String questionId = rawQuestionId.isEmpty
          ? '${themeId}_d${difficulty}_q${questionIndex + 1}'
          : rawQuestionId;
      final String text = (questionJson['text'] as String? ?? '').trim();
      final String answer = (questionJson['answer'] as String? ?? '').trim();
      if (text.isEmpty || answer.isEmpty) {
        continue;
      }

      variantsByDifficulty
          .putIfAbsent(difficulty, () => <_QuestionVariant>[])
          .add(
            _QuestionVariant(
              id: questionId,
              difficulty: difficulty,
              text: text,
              answer: answer,
            ),
          );
    }

    themes.add(
      _ThemePool(
        id: themeId,
        title: title,
        variantsByDifficulty: variantsByDifficulty,
      ),
    );
  }
  return themes;
}

List<Question> _buildStructuredQuestionSet(
  List<_ThemePool> themes, {
  required int rounds,
  Random? random,
}) {
  final List<_ThemePool> eligibleThemes =
      themes.where(_hasPlayableTheme).toList(growable: false);
  final int requiredThemeCount = rounds * 5;
  if (eligibleThemes.length < requiredThemeCount) {
    throw StateError(
      'Question package requires at least $requiredThemeCount themes '
      'with 5 questions for each difficulty.',
    );
  }

  final List<_ThemePool> selectedThemes = List<_ThemePool>.from(eligibleThemes);
  if (random != null) {
    _shuffle(selectedThemes, random);
  }
  final List<_ThemePool> pickedThemes =
      selectedThemes.take(requiredThemeCount).toList(growable: false);

  final List<Question> result = <Question>[];
  for (int roundIndex = 0; roundIndex < rounds; roundIndex++) {
    final int roundNumber = roundIndex + 1;
    final List<_ThemePool> roundThemes =
        pickedThemes.skip(roundIndex * 5).take(5).toList(growable: false);
    for (final _ThemePool theme in roundThemes) {
      for (int difficulty = 1; difficulty <= 5; difficulty++) {
        final List<_QuestionVariant> variants =
            theme.variantsByDifficulty[difficulty]!;
        final _QuestionVariant selected = random == null
            ? variants.first
            : variants[random.nextInt(variants.length)];
        result.add(
          Question(
            id: '${selected.id}_r$roundNumber',
            text: selected.text,
            answer: selected.answer,
            category: theme.title,
            value: difficulty * 100 * roundNumber,
            used: false,
            round: roundNumber,
          ),
        );
      }
    }
  }
  return result;
}

bool _hasPlayableTheme(_ThemePool theme) {
  for (int difficulty = 1; difficulty <= 5; difficulty++) {
    final List<_QuestionVariant> variants =
        theme.variantsByDifficulty[difficulty] ?? const <_QuestionVariant>[];
    if (variants.length < 5) {
      return false;
    }
  }
  return true;
}

void _shuffle<T>(List<T> items, Random random) {
  for (int index = items.length - 1; index > 0; index--) {
    final int swapIndex = random.nextInt(index + 1);
    final T value = items[index];
    items[index] = items[swapIndex];
    items[swapIndex] = value;
  }
}

class _ThemePool {
  const _ThemePool({
    required this.id,
    required this.title,
    required this.variantsByDifficulty,
  });

  final String id;
  final String title;
  final Map<int, List<_QuestionVariant>> variantsByDifficulty;
}

class _QuestionVariant {
  const _QuestionVariant({
    required this.id,
    required this.difficulty,
    required this.text,
    required this.answer,
  });

  final String id;
  final int difficulty;
  final String text;
  final String answer;
}

class QuestionLocalizationCatalog {
  QuestionLocalizationCatalog._(this._contentBySourceId);

  final Map<String, _LocalizedQuestionContent> _contentBySourceId;

  Question localizeQuestion(Question question) {
    final _LocalizedQuestionContent? content =
        _contentBySourceId[_sourceQuestionId(question.id)];
    if (content == null) {
      return question;
    }
    return question.copyWith(
      text: content.text.isEmpty ? question.text : content.text,
      answer: content.answer.isEmpty ? question.answer : content.answer,
      category: content.category.isEmpty ? question.category : content.category,
      used: question.used,
      round: question.round,
    );
  }

  List<Question> localizeQuestions(Iterable<Question> questions) {
    return questions.map(localizeQuestion).toList(growable: false);
  }

  GameState localizeGameState(GameState state) {
    final List<Question> localizedBoardQuestions =
        localizeQuestions(state.boardQuestions);
    Question? localizedCurrentQuestion;
    final Question? currentQuestion = state.currentQuestion;
    if (currentQuestion != null) {
      for (final Question question in localizedBoardQuestions) {
        if (question.id == currentQuestion.id) {
          localizedCurrentQuestion = question;
          break;
        }
      }
      localizedCurrentQuestion ??= localizeQuestion(currentQuestion);
    }

    return state.copyWith(
      boardQuestions: localizedBoardQuestions,
      currentQuestion: localizedCurrentQuestion,
      clearCurrentQuestion: currentQuestion == null,
    );
  }
}

class _LocalizedQuestionContent {
  const _LocalizedQuestionContent({
    required this.text,
    required this.answer,
    required this.category,
  });

  final String text;
  final String answer;
  final String category;
}

String _sourceQuestionId(String questionId) {
  return questionId.replaceFirst(RegExp(r'_r\d+$'), '');
}
