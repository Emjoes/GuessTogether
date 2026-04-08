// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Guess Together';

  @override
  String get splashTagline => 'Play quiz shows with friends in minutes.';

  @override
  String get homeCreateRoom => 'Create Room';

  @override
  String get homeJoinByPassword => 'Join Game';

  @override
  String get homeProfile => 'My Profile';

  @override
  String get homeSettings => 'Settings';

  @override
  String get createRoomTitle => 'Create Room';

  @override
  String get createRoomDetailsLabel => 'Room details';

  @override
  String get createRoomNameLabel => 'Room name';

  @override
  String get createRoomNameHint => 'Cool Quiz';

  @override
  String get createRoomPasswordLabel => 'Password';

  @override
  String get createRoomPasswordHint => '1234';

  @override
  String get createRoomModeLabel => 'Game mode';

  @override
  String get createRoomModeMultiplayer => 'Multiplayer';

  @override
  String get createRoomModeDuel => 'Duel';

  @override
  String get createRoomPackageLabel => 'Package';

  @override
  String get createRoomPackageSoon => 'Soon';

  @override
  String get createRoomPackagePick => 'Choose file';

  @override
  String get createRoomCreateCta => 'Create';

  @override
  String get createRoomFilePickerError => 'Could not open file picker';

  @override
  String get joinRoomTitle => 'Join Game';

  @override
  String get joinRoomErrorInvalid => 'Room not found. Check the code.';

  @override
  String get joinRoomErrorWrongPassword => 'Wrong password. Try again.';

  @override
  String get joinRoomSearchLabel => 'Search';

  @override
  String get joinRoomSearchHint => 'Room name';

  @override
  String get joinRoomSearchHintText => 'Cool Quiz';

  @override
  String get joinRoomActiveLobbies => 'Active rooms';

  @override
  String get joinRoomTableRoom => 'Room';

  @override
  String get joinRoomTablePlayers => 'Players';

  @override
  String get joinRoomTableType => 'Type';

  @override
  String get joinRoomTablePassword => 'Pass';

  @override
  String get joinRoomNoLobbies => 'No active rooms found';

  @override
  String get joinRoomPasswordDialogTitle => 'Password required';

  @override
  String get joinRoomPasswordDialogHint => '1234';

  @override
  String get joinRoomPasswordJoinCta => 'Join';

  @override
  String joinRoomPlayersCount(int current, int max) {
    return '$current/$max';
  }

  @override
  String get profileTitle => 'My Profile';

  @override
  String get profileStatsLabel => 'Game statistics';

  @override
  String get profileGamesPlayed => 'Games';

  @override
  String get profileWins => 'Wins';

  @override
  String get profileLosses => 'Losses';

  @override
  String get profileRecentGames => 'Recent games';

  @override
  String get profileNoRecentGames => 'No recent games yet';

  @override
  String get profileAchievements => 'Achievements';

  @override
  String get profileUnlocked => 'unlocked';

  @override
  String get profileLeaderboards => 'Leaderboards';

  @override
  String get profileTabStats => 'Statistics';

  @override
  String get profileTabLeaderboards => 'Leaders';

  @override
  String get profileTabAchievements => 'Achievements';

  @override
  String get profileLeaderboardGlobal => 'Global';

  @override
  String get profileLeaderboardMonth => 'Month';

  @override
  String get profileLeaderboardDay => 'Day';

  @override
  String get profileShowCompleted => 'Show completed';

  @override
  String get profileNoLeaderboardData => 'No leaderboard data';

  @override
  String get profileLoadFailed => 'Failed to load profile';

  @override
  String get profileWinLabel => 'Win';

  @override
  String get profileLossLabel => 'Loss';

  @override
  String get profileGameTimeJustNow => 'just now';

  @override
  String get profileGameTimeToday => 'today';

  @override
  String get profileGameTimeYesterday => 'yesterday';

  @override
  String get profileGameTimeTwoDaysAgo => '2 days ago';

  @override
  String profileXpProgress(int currentXp, int xpPerLevel) {
    return '$currentXp / $xpPerLevel XP';
  }

  @override
  String profileXpToNextLevel(int xp) {
    return '$xp XP to next level';
  }

  @override
  String profileUnlockedCount(int unlocked, int total) {
    return '$unlocked / $total unlocked';
  }

  @override
  String profileProgressValue(int progress, int target) {
    return '$progress / $target';
  }

  @override
  String profileRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String get profileRecentGameFridayTriviaCrew => 'Friday Trivia Crew';

  @override
  String get profileRecentGameMovieLegends => 'Movie Legends';

  @override
  String get profileRecentGameNightBlitz => 'Night Blitz';

  @override
  String get profileRecentGameQuickSparks => 'Quick Sparks';

  @override
  String get achievementFirstWinTitle => 'First Win';

  @override
  String get achievementFirstWinRequirement => 'Win any match';

  @override
  String get achievementClutchAnswerTitle => 'Clutch Answer';

  @override
  String get achievementClutchAnswerRequirement =>
      'Give a correct answer after all other players answered wrong';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageRussian => 'Русский';

  @override
  String get gameWaitingForPlayers => 'Waiting for players...';

  @override
  String get gameTapToReveal => 'Tap a tile to reveal a question';

  @override
  String get gameAnswerCta => 'Answer';

  @override
  String get gameLiveMatchTitle => 'Live Match';

  @override
  String get gameMatchEnded => 'Match ended';

  @override
  String get gameStartScriptedMatch => 'Start scripted match';

  @override
  String get gameLeaveDialogTitle => 'Leave match?';

  @override
  String get gameLeaveDialogBody => 'You can reconnect to this match later.';

  @override
  String get gameLeaveDialogBodyHost =>
      'If the host leaves, the room will be destroyed for all players.';

  @override
  String get gameHostLeftMatchMessage => 'Host left the game - match was ended';

  @override
  String get gameLeaveStay => 'Stay';

  @override
  String get gameLeaveLeave => 'Leave';

  @override
  String gameScoreDialogTitle(String playerName) {
    return 'Set score: $playerName';
  }

  @override
  String get gameScoreFieldLabel => 'Score';

  @override
  String get gameScoreFieldHint => '0';

  @override
  String get gameScoreDialogCancel => 'Cancel';

  @override
  String get gameScoreDialogSave => 'Save';

  @override
  String get gameScoresDialogTitle => 'Scores';

  @override
  String get gameHostStartCta => 'Start';

  @override
  String get gameHostPauseCta => 'Pause';

  @override
  String get gameHostUnpauseCta => 'Unpause';

  @override
  String get gameHostScoresCta => 'Scores';

  @override
  String get gameCopyLinkCta => 'Link';

  @override
  String get gameConnectLinkCopied => 'Connect link copied';

  @override
  String get gameHostAcceptCta => 'Accept';

  @override
  String get gameHostRejectCta => 'Reject';

  @override
  String get gamePassCta => 'Pass';

  @override
  String get gameHostShouldStartMatch => 'Host should start the match.';

  @override
  String get gameMatchFinishedBody => 'Match finished.';

  @override
  String get gameNoActiveClueBody => 'No active clue.';

  @override
  String get gameCorrectAnswerLabel => 'Correct answer';

  @override
  String gamePointsLabel(int points) {
    return '$points pts';
  }

  @override
  String get gameBoardSpace200 => 'Space 200';

  @override
  String get gameBoardScience200 => 'Science 200';

  @override
  String get gameBoardGeography400 => 'Geography 400';

  @override
  String get gameBoardHistory400 => 'History 400';

  @override
  String get gameFinalWagerTitle => 'Final Wager';

  @override
  String get resultsTitle => 'Results';

  @override
  String get resultsPlayAgain => 'Play again';

  @override
  String get resultsShare => 'Share';

  @override
  String get resultWinner => 'Winner';

  @override
  String resultPointsLabel(int points) {
    return '$points pts';
  }

  @override
  String get waitingRoomTitle => 'Waiting Room';

  @override
  String get waitingRoomHostPreparing => 'Host must start the match';

  @override
  String get waitingRoomNeedPlayers =>
      'At least 2 players are required to start';

  @override
  String get waitingRoomSyncingPlayers => 'Syncing players...';

  @override
  String get playerRowWaitingRoster => 'Waiting for roster...';

  @override
  String timerSemanticsRemaining(int seconds) {
    return 'Timer, $seconds seconds remaining';
  }
}
