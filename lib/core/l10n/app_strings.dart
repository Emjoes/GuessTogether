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
  static const String createRoomNameLabel = 'Room name';
  static const String createRoomPasswordLabel = 'Password';
  static const String createRoomModeLabel = 'Game mode';
  static const String createRoomModeMultiplayer = 'Multiplayer';
  static const String createRoomModeDuel = 'Duel';
  static const String createRoomPlayersLabel = 'Players';
  static const String createRoomDuelHint = 'Duel mode is always 2 players';
  static const String createRoomCreateCta = 'Create';

  // Join room
  static const String joinRoomTitle = 'Join by Password';
  static const String joinRoomCodeLabel = 'Room code';
  static const String joinRoomRecent = 'Recent rooms';
  static const String joinRoomQrStub = 'Join via QR (coming soon)';
  static const String joinRoomErrorInvalid = 'Room not found. Check the code.';

  // Profile
  static const String profileTitle = 'Profile';
  static const String profileGamesPlayed = 'Games played';
  static const String profileWinRate = 'Win rate';
  static const String profileBestScore = 'Best score';
  static const String profileAchievements = 'Achievements';
  static const String profileLeaderboards = 'Leaderboards';
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
