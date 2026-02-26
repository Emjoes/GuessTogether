// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Guess Together';

  @override
  String get splashTagline => 'Играйте в викторины с друзьями за пару минут.';

  @override
  String get homeCreateRoom => 'Создать комнату';

  @override
  String get homeJoinByPassword => 'Войти в игру';

  @override
  String get homeProfile => 'Мой профиль';

  @override
  String get homeSettings => 'Настройки';

  @override
  String get createRoomTitle => 'Создать комнату';

  @override
  String get createRoomDetailsLabel => 'Параметры комнаты';

  @override
  String get createRoomNameLabel => 'Название комнаты';

  @override
  String get createRoomNameHint => 'Крутой квиз';

  @override
  String get createRoomPasswordLabel => 'Пароль';

  @override
  String get createRoomPasswordHint => '1234';

  @override
  String get createRoomModeLabel => 'Режим игры';

  @override
  String get createRoomModeMultiplayer => 'Мультиплеер';

  @override
  String get createRoomModeDuel => 'Дуэль';

  @override
  String get createRoomPackageLabel => 'Пакет вопросов';

  @override
  String get createRoomPackagePick => 'Выбрать файл';

  @override
  String get createRoomCreateCta => 'Создать';

  @override
  String get createRoomFilePickerError => 'Не удалось открыть выбор файла';

  @override
  String get joinRoomTitle => 'Войти в игру';

  @override
  String get joinRoomErrorInvalid => 'Комната не найдена. Проверьте код.';

  @override
  String get joinRoomErrorWrongPassword => 'Неверный пароль. Попробуйте снова.';

  @override
  String get joinRoomSearchLabel => 'Поиск';

  @override
  String get joinRoomSearchHint => 'Название комнаты';

  @override
  String get joinRoomSearchHintText => 'Крутой квиз';

  @override
  String get joinRoomActiveLobbies => 'Активные комнаты';

  @override
  String get joinRoomTableRoom => 'Комната';

  @override
  String get joinRoomTablePlayers => 'Игроки';

  @override
  String get joinRoomTableType => 'Тип';

  @override
  String get joinRoomTablePassword => 'Пароль';

  @override
  String get joinRoomNoLobbies => 'Активные комнаты не найдены';

  @override
  String get joinRoomPasswordDialogTitle => 'Требуется пароль';

  @override
  String get joinRoomPasswordDialogHint => '1234';

  @override
  String get joinRoomPasswordJoinCta => 'Войти';

  @override
  String joinRoomPlayersCount(int current, int max) {
    return '$current/$max';
  }

  @override
  String get profileTitle => 'Мой профиль';

  @override
  String get profileStatsLabel => 'Статистика игр';

  @override
  String get profileGamesPlayed => 'Игр';

  @override
  String get profileWins => 'Побед';

  @override
  String get profileLosses => 'Поражений';

  @override
  String get profileRecentGames => 'Недавние игры';

  @override
  String get profileAchievements => 'Достижения';

  @override
  String get profileUnlocked => 'открыто';

  @override
  String get profileLeaderboards => 'Рейтинги';

  @override
  String get profileTabStats => 'Статистика';

  @override
  String get profileTabLeaderboards => 'Лидеры';

  @override
  String get profileTabAchievements => 'Достижения';

  @override
  String get profileLeaderboardGlobal => 'Общий';

  @override
  String get profileLeaderboardFriends => 'Друзья';

  @override
  String get profileLeaderboardWeekly => 'Неделя';

  @override
  String get profileShowCompleted => 'Показывать выполненные';

  @override
  String get profileNoLeaderboardData => 'Нет данных рейтинга';

  @override
  String get profileLoadFailed => 'Не удалось загрузить профиль';

  @override
  String get profileWinLabel => 'Победа';

  @override
  String get profileLossLabel => 'Поражение';

  @override
  String get profileGameTimeJustNow => 'только что';

  @override
  String get profileGameTimeToday => 'сегодня';

  @override
  String get profileGameTimeYesterday => 'вчера';

  @override
  String get profileGameTimeTwoDaysAgo => '2 дня назад';

  @override
  String profileXpProgress(int currentXp, int xpPerLevel) {
    return '$currentXp / $xpPerLevel XP';
  }

  @override
  String profileXpToNextLevel(int xp) {
    return 'До следующего уровня: $xp XP';
  }

  @override
  String profileUnlockedCount(int unlocked, int total) {
    return '$unlocked/$total открыто';
  }

  @override
  String profileProgressValue(int progress, int target) {
    return '$progress/$target';
  }

  @override
  String profileRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String get profileRecentGameFridayTriviaCrew => 'Пятничная викторина';

  @override
  String get profileRecentGameMovieLegends => 'Легенды кино';

  @override
  String get profileRecentGameNightBlitz => 'Ночной блиц';

  @override
  String get profileRecentGameQuickSparks => 'Быстрые искры';

  @override
  String get achievementPerfectRoundTitle => 'Идеальный раунд';

  @override
  String get achievementPerfectRoundRequirement =>
      'Ответьте правильно на все вопросы в одном раунде';

  @override
  String get achievementConsistentWinnerTitle => 'Стабильный победитель';

  @override
  String get achievementConsistentWinnerRequirement => 'Выиграйте 20 игр';

  @override
  String get achievementXpCollectorTitle => 'Коллекционер XP';

  @override
  String get achievementXpCollectorRequirement => 'Наберите 10 000 XP';

  @override
  String get achievementDailyChallengerTitle => 'Ежедневный соперник';

  @override
  String get achievementDailyChallengerRequirement => 'Сыграйте 30 игр';

  @override
  String get achievementStreakRunnerTitle => 'Серия побед';

  @override
  String get achievementStreakRunnerRequirement =>
      'Удерживайте серию из 5 побед';

  @override
  String get achievementVeteranMindTitle => 'Ветеран ума';

  @override
  String get achievementVeteranMindRequirement => 'Достигните 8 уровня';

  @override
  String get achievementArenaMasterTitle => 'Мастер арены';

  @override
  String get achievementArenaMasterRequirement => 'Достигните 12 уровня';

  @override
  String get achievementMarathonPlayerTitle => 'Игрок-марафонец';

  @override
  String get achievementMarathonPlayerRequirement => 'Сыграйте 60 игр';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsThemeSystem => 'Системная';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageSystem => 'Системный';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageRussian => 'Русский';

  @override
  String get gameWaitingForPlayers => 'Ожидание игроков...';

  @override
  String get gameTapToReveal => 'Нажмите на плитку, чтобы открыть вопрос';

  @override
  String get gameAnswerCta => 'Ответить';

  @override
  String get gameLiveMatchTitle => 'Матч';

  @override
  String get gameMatchEnded => 'Матч завершён';

  @override
  String get gameStartScriptedMatch => 'Запустить тестовый матч';

  @override
  String gamePointsLabel(int points) {
    return '$points очков';
  }

  @override
  String get gameBoardSpace200 => 'Космос 200';

  @override
  String get gameBoardScience200 => 'Наука 200';

  @override
  String get gameBoardGeography400 => 'География 400';

  @override
  String get gameBoardHistory400 => 'История 400';

  @override
  String get gameFinalWagerTitle => 'Финальная ставка';

  @override
  String get resultsTitle => 'Результаты';

  @override
  String get resultsPlayAgain => 'Играть снова';

  @override
  String get resultsShare => 'Поделиться';

  @override
  String get resultWinner => 'Победитель';

  @override
  String resultPointsLabel(int points) {
    return '$points очков';
  }

  @override
  String get waitingRoomTitle => 'Комната ожидания';

  @override
  String get waitingRoomHostPreparing =>
      'Ведущий готовит поле. Оставайтесь на этом экране.';

  @override
  String get waitingRoomSyncingPlayers => 'Синхронизация игроков...';

  @override
  String get playerRowWaitingRoster => 'Ожидание списка игроков...';

  @override
  String timerSemanticsRemaining(int seconds) {
    return 'Таймер: осталось $seconds сек.';
  }
}
