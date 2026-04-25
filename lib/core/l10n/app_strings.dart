/// Central place for user-visible strings to keep the app
/// localization-ready. Currently English only with placeholders.
class AppStrings {
  AppStrings._();

  // General
  static const String appTitle = 'Guess Together';

  // Splash
  static const String splashTagline =
      'Play quiz shows with friends in minutes.';

  // Home
  static const String homeCreateRoom = 'Create Room';
  static const String homeJoinByPassword = 'Join Game';
  static const String homeProfile = 'My Profile';
  static const String homeQuickMatch = 'Play Quick Match';
  static const String homeSettings = 'Settings';

  // Create room
  static const String createRoomTitle = 'Create Room';
  static const String createRoomDetailsLabel = 'Room details';
  static const String createRoomNameLabel = 'Room name';
  static const String createRoomPasswordLabel = 'Password';
  static const String createRoomModeLabel = 'Game mode';
  static const String createRoomModeMultiplayer = 'Multiplayer';
  static const String createRoomModeDuel = 'Elimination';
  static const String createRoomPackageLabel = 'Package';
  static const String createRoomPackageSoon = 'Soon';
  static const String createRoomPackagePick = 'Choose file';
  static const String createRoomPackageEmpty = 'No file selected';
  static const String createRoomPlayersLabel = 'Players';
  static const String createRoomDuelHint =
      'Elimination mode is always 2 players';
  static const String createRoomCreateCta = 'Create';

  // Join room
  static const String joinRoomTitle = 'Join Game';
  static const String joinRoomCodeLabel = 'Room code';
  static const String joinRoomRecent = 'Recent rooms';
  static const String joinRoomQrStub = 'Join via QR (coming soon)';
  static const String joinRoomErrorInvalid = 'Room not found. Check the code.';
  static const String joinRoomErrorWrongPassword = 'Wrong password. Try again.';
  static const String joinRoomSearchLabel = 'Search';
  static const String joinRoomSearchHint = 'Room name';
  static const String joinRoomActiveLobbies = 'Active rooms';
  static const String joinRoomTableRoom = 'Room';
  static const String joinRoomTablePlayers = 'Players';
  static const String joinRoomTableType = 'Type';
  static const String joinRoomTablePassword = 'Pass';
  static const String joinRoomNoLobbies = 'No active rooms found';
  static const String joinRoomPasswordDialogTitle = 'Password required';
  static const String joinRoomPasswordDialogHint = '1234';
  static const String joinRoomPasswordJoinCta = 'Join';

  // Profile
  static const String profileTitle = 'Profile';
  static const String profileStatsLabel = 'Game statistics';
  static const String profileGamesPlayed = 'Games';
  static const String profileWins = 'Wins';
  static const String profileLosses = 'Losses';
  static const String profileWinRate = 'Win rate';
  static const String profileAverageScore = 'Avg score';
  static const String profileBestScore = 'Best score';
  static const String profileLevel = 'Level';
  static const String profileXpToNextLevel = 'to next level';
  static const String profileRecentGames = 'Recent games';
  static const String profileUserRoleSubtitle = 'Competitive quiz strategist';
  static const String profileWinStreak = 'streak';
  static const String profileWinLabel = 'Win';
  static const String profileLossLabel = 'Loss';
  static const String profileGameTimeJustNow = 'just now';
  static const String profileGameTimeToday = 'today';
  static const String profileGameTimeYesterday = 'yesterday';
  static const String profileGameTimeTwoDaysAgo = '2 days ago';
  static const String profileAchievements = 'Achievements';
  static const String profileUnlocked = 'unlocked';
  static const String profileLeaderboards = 'Leaderboards';
  static const String profileTabStats = 'Statistics';
  static const String profileTabLeaderboards = 'Leaders';
  static const String profileTabAchievements = 'Achievements';
  static const String profileYourRank = 'Your rank';
  static const String profileRating = 'Rating';
  static const String profileLeaderboardGlobal = 'Global';
  static const String profileLeaderboardMonth = 'Month';
  static const String profileLeaderboardDay = 'Day';
  static const String profilePlayersRankedByLevel =
      'Players are ranked by level';
  static const String profileYourPosition = 'Your position';
  static const String profileAchievementGuide =
      'Complete requirements to unlock rewards';
  static const String profileShowCompleted = 'Show completed achievements';
  static const String profileToUnlock = 'To unlock';
  static const String profileReward = 'Reward';
  static const String profileClaimed = 'Claimed';
  static const String profileNoLeaderboardData = 'No leaderboard data';
  static const String profileLoadFailed = 'Failed to load profile';
  static const String profileEdit = 'Edit profile';

  // Game
  static const String gameWaitingForPlayers = 'Waiting for players...';
  static const String gameTapToReveal = 'Tap a tile to reveal a question';
  static const String gameAnswerCta = 'Answer';
  static const String gameFinalWagerTitle = 'Final Wager';

  // Results
  static const String resultsTitle = 'Results';
  static const String resultsPlayAgain = 'Play again';
  static const String resultsShare = 'Share';

  // Settings
  static const String settingsTitle = 'Settings';
  static const String settingsTheme = 'Theme';
  static const String settingsThemeLight = 'Light';
  static const String settingsThemeDark = 'Dark';
  static const String settingsThemeSystem = 'System';
}
