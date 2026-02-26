import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Guess Together'**
  String get appTitle;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Play quiz shows with friends in minutes.'**
  String get splashTagline;

  /// No description provided for @homeCreateRoom.
  ///
  /// In en, this message translates to:
  /// **'Create Room'**
  String get homeCreateRoom;

  /// No description provided for @homeJoinByPassword.
  ///
  /// In en, this message translates to:
  /// **'Join Game'**
  String get homeJoinByPassword;

  /// No description provided for @homeProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get homeProfile;

  /// No description provided for @homeSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettings;

  /// No description provided for @createRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Room'**
  String get createRoomTitle;

  /// No description provided for @createRoomDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Room details'**
  String get createRoomDetailsLabel;

  /// No description provided for @createRoomNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Room name'**
  String get createRoomNameLabel;

  /// No description provided for @createRoomNameHint.
  ///
  /// In en, this message translates to:
  /// **'Cool Quiz'**
  String get createRoomNameHint;

  /// No description provided for @createRoomPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get createRoomPasswordLabel;

  /// No description provided for @createRoomPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'1234'**
  String get createRoomPasswordHint;

  /// No description provided for @createRoomModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Game mode'**
  String get createRoomModeLabel;

  /// No description provided for @createRoomModeMultiplayer.
  ///
  /// In en, this message translates to:
  /// **'Multiplayer'**
  String get createRoomModeMultiplayer;

  /// No description provided for @createRoomModeDuel.
  ///
  /// In en, this message translates to:
  /// **'Duel'**
  String get createRoomModeDuel;

  /// No description provided for @createRoomPackageLabel.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get createRoomPackageLabel;

  /// No description provided for @createRoomPackagePick.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get createRoomPackagePick;

  /// No description provided for @createRoomCreateCta.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createRoomCreateCta;

  /// No description provided for @createRoomFilePickerError.
  ///
  /// In en, this message translates to:
  /// **'Could not open file picker'**
  String get createRoomFilePickerError;

  /// No description provided for @joinRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Game'**
  String get joinRoomTitle;

  /// No description provided for @joinRoomErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Room not found. Check the code.'**
  String get joinRoomErrorInvalid;

  /// No description provided for @joinRoomErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password. Try again.'**
  String get joinRoomErrorWrongPassword;

  /// No description provided for @joinRoomSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get joinRoomSearchLabel;

  /// No description provided for @joinRoomSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Room name'**
  String get joinRoomSearchHint;

  /// No description provided for @joinRoomSearchHintText.
  ///
  /// In en, this message translates to:
  /// **'Cool Quiz'**
  String get joinRoomSearchHintText;

  /// No description provided for @joinRoomActiveLobbies.
  ///
  /// In en, this message translates to:
  /// **'Active rooms'**
  String get joinRoomActiveLobbies;

  /// No description provided for @joinRoomTableRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get joinRoomTableRoom;

  /// No description provided for @joinRoomTablePlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get joinRoomTablePlayers;

  /// No description provided for @joinRoomTableType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get joinRoomTableType;

  /// No description provided for @joinRoomTablePassword.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get joinRoomTablePassword;

  /// No description provided for @joinRoomNoLobbies.
  ///
  /// In en, this message translates to:
  /// **'No active rooms found'**
  String get joinRoomNoLobbies;

  /// No description provided for @joinRoomPasswordDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Password required'**
  String get joinRoomPasswordDialogTitle;

  /// No description provided for @joinRoomPasswordDialogHint.
  ///
  /// In en, this message translates to:
  /// **'1234'**
  String get joinRoomPasswordDialogHint;

  /// No description provided for @joinRoomPasswordJoinCta.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinRoomPasswordJoinCta;

  /// No description provided for @joinRoomPlayersCount.
  ///
  /// In en, this message translates to:
  /// **'{current}/{max}'**
  String joinRoomPlayersCount(int current, int max);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileTitle;

  /// No description provided for @profileStatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Game statistics'**
  String get profileStatsLabel;

  /// No description provided for @profileGamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get profileGamesPlayed;

  /// No description provided for @profileWins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get profileWins;

  /// No description provided for @profileLosses.
  ///
  /// In en, this message translates to:
  /// **'Losses'**
  String get profileLosses;

  /// No description provided for @profileRecentGames.
  ///
  /// In en, this message translates to:
  /// **'Recent games'**
  String get profileRecentGames;

  /// No description provided for @profileAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get profileAchievements;

  /// No description provided for @profileUnlocked.
  ///
  /// In en, this message translates to:
  /// **'unlocked'**
  String get profileUnlocked;

  /// No description provided for @profileLeaderboards.
  ///
  /// In en, this message translates to:
  /// **'Leaderboards'**
  String get profileLeaderboards;

  /// No description provided for @profileTabStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get profileTabStats;

  /// No description provided for @profileTabLeaderboards.
  ///
  /// In en, this message translates to:
  /// **'Leaders'**
  String get profileTabLeaderboards;

  /// No description provided for @profileTabAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get profileTabAchievements;

  /// No description provided for @profileLeaderboardGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get profileLeaderboardGlobal;

  /// No description provided for @profileLeaderboardFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get profileLeaderboardFriends;

  /// No description provided for @profileLeaderboardWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get profileLeaderboardWeekly;

  /// No description provided for @profileShowCompleted.
  ///
  /// In en, this message translates to:
  /// **'Show completed'**
  String get profileShowCompleted;

  /// No description provided for @profileNoLeaderboardData.
  ///
  /// In en, this message translates to:
  /// **'No leaderboard data'**
  String get profileNoLeaderboardData;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get profileLoadFailed;

  /// No description provided for @profileWinLabel.
  ///
  /// In en, this message translates to:
  /// **'Win'**
  String get profileWinLabel;

  /// No description provided for @profileLossLabel.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get profileLossLabel;

  /// No description provided for @profileGameTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get profileGameTimeJustNow;

  /// No description provided for @profileGameTimeToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get profileGameTimeToday;

  /// No description provided for @profileGameTimeYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get profileGameTimeYesterday;

  /// No description provided for @profileGameTimeTwoDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'2 days ago'**
  String get profileGameTimeTwoDaysAgo;

  /// No description provided for @profileXpProgress.
  ///
  /// In en, this message translates to:
  /// **'{currentXp} / {xpPerLevel} XP'**
  String profileXpProgress(int currentXp, int xpPerLevel);

  /// No description provided for @profileXpToNextLevel.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP to next level'**
  String profileXpToNextLevel(int xp);

  /// No description provided for @profileUnlockedCount.
  ///
  /// In en, this message translates to:
  /// **'{unlocked}/{total} unlocked'**
  String profileUnlockedCount(int unlocked, int total);

  /// No description provided for @profileProgressValue.
  ///
  /// In en, this message translates to:
  /// **'{progress}/{target}'**
  String profileProgressValue(int progress, int target);

  /// No description provided for @profileRewardXp.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String profileRewardXp(int xp);

  /// No description provided for @profileRecentGameFridayTriviaCrew.
  ///
  /// In en, this message translates to:
  /// **'Friday Trivia Crew'**
  String get profileRecentGameFridayTriviaCrew;

  /// No description provided for @profileRecentGameMovieLegends.
  ///
  /// In en, this message translates to:
  /// **'Movie Legends'**
  String get profileRecentGameMovieLegends;

  /// No description provided for @profileRecentGameNightBlitz.
  ///
  /// In en, this message translates to:
  /// **'Night Blitz'**
  String get profileRecentGameNightBlitz;

  /// No description provided for @profileRecentGameQuickSparks.
  ///
  /// In en, this message translates to:
  /// **'Quick Sparks'**
  String get profileRecentGameQuickSparks;

  /// No description provided for @achievementPerfectRoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Perfect Round'**
  String get achievementPerfectRoundTitle;

  /// No description provided for @achievementPerfectRoundRequirement.
  ///
  /// In en, this message translates to:
  /// **'Answer every question correctly in one round'**
  String get achievementPerfectRoundRequirement;

  /// No description provided for @achievementConsistentWinnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Consistent Winner'**
  String get achievementConsistentWinnerTitle;

  /// No description provided for @achievementConsistentWinnerRequirement.
  ///
  /// In en, this message translates to:
  /// **'Win 20 games'**
  String get achievementConsistentWinnerRequirement;

  /// No description provided for @achievementXpCollectorTitle.
  ///
  /// In en, this message translates to:
  /// **'XP Collector'**
  String get achievementXpCollectorTitle;

  /// No description provided for @achievementXpCollectorRequirement.
  ///
  /// In en, this message translates to:
  /// **'Reach 10,000 total XP'**
  String get achievementXpCollectorRequirement;

  /// No description provided for @achievementDailyChallengerTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenger'**
  String get achievementDailyChallengerTitle;

  /// No description provided for @achievementDailyChallengerRequirement.
  ///
  /// In en, this message translates to:
  /// **'Play 30 games'**
  String get achievementDailyChallengerRequirement;

  /// No description provided for @achievementStreakRunnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Streak Runner'**
  String get achievementStreakRunnerTitle;

  /// No description provided for @achievementStreakRunnerRequirement.
  ///
  /// In en, this message translates to:
  /// **'Maintain 5-win streak'**
  String get achievementStreakRunnerRequirement;

  /// No description provided for @achievementVeteranMindTitle.
  ///
  /// In en, this message translates to:
  /// **'Veteran Mind'**
  String get achievementVeteranMindTitle;

  /// No description provided for @achievementVeteranMindRequirement.
  ///
  /// In en, this message translates to:
  /// **'Reach level 8'**
  String get achievementVeteranMindRequirement;

  /// No description provided for @achievementArenaMasterTitle.
  ///
  /// In en, this message translates to:
  /// **'Arena Master'**
  String get achievementArenaMasterTitle;

  /// No description provided for @achievementArenaMasterRequirement.
  ///
  /// In en, this message translates to:
  /// **'Reach level 12'**
  String get achievementArenaMasterRequirement;

  /// No description provided for @achievementMarathonPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Marathon Player'**
  String get achievementMarathonPlayerTitle;

  /// No description provided for @achievementMarathonPlayerRequirement.
  ///
  /// In en, this message translates to:
  /// **'Play 60 games'**
  String get achievementMarathonPlayerRequirement;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get settingsLanguageRussian;

  /// No description provided for @gameWaitingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for players...'**
  String get gameWaitingForPlayers;

  /// No description provided for @gameTapToReveal.
  ///
  /// In en, this message translates to:
  /// **'Tap a tile to reveal a question'**
  String get gameTapToReveal;

  /// No description provided for @gameAnswerCta.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get gameAnswerCta;

  /// No description provided for @gameLiveMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Match'**
  String get gameLiveMatchTitle;

  /// No description provided for @gameMatchEnded.
  ///
  /// In en, this message translates to:
  /// **'Match ended'**
  String get gameMatchEnded;

  /// No description provided for @gameStartScriptedMatch.
  ///
  /// In en, this message translates to:
  /// **'Start scripted match'**
  String get gameStartScriptedMatch;

  /// No description provided for @gamePointsLabel.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String gamePointsLabel(int points);

  /// No description provided for @gameBoardSpace200.
  ///
  /// In en, this message translates to:
  /// **'Space 200'**
  String get gameBoardSpace200;

  /// No description provided for @gameBoardScience200.
  ///
  /// In en, this message translates to:
  /// **'Science 200'**
  String get gameBoardScience200;

  /// No description provided for @gameBoardGeography400.
  ///
  /// In en, this message translates to:
  /// **'Geography 400'**
  String get gameBoardGeography400;

  /// No description provided for @gameBoardHistory400.
  ///
  /// In en, this message translates to:
  /// **'History 400'**
  String get gameBoardHistory400;

  /// No description provided for @gameFinalWagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Final Wager'**
  String get gameFinalWagerTitle;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get resultsTitle;

  /// No description provided for @resultsPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get resultsPlayAgain;

  /// No description provided for @resultsShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get resultsShare;

  /// No description provided for @resultWinner.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get resultWinner;

  /// No description provided for @resultPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String resultPointsLabel(int points);

  /// No description provided for @waitingRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting Room'**
  String get waitingRoomTitle;

  /// No description provided for @waitingRoomHostPreparing.
  ///
  /// In en, this message translates to:
  /// **'Host is preparing the board. Stay on this screen.'**
  String get waitingRoomHostPreparing;

  /// No description provided for @waitingRoomSyncingPlayers.
  ///
  /// In en, this message translates to:
  /// **'Syncing players...'**
  String get waitingRoomSyncingPlayers;

  /// No description provided for @playerRowWaitingRoster.
  ///
  /// In en, this message translates to:
  /// **'Waiting for roster...'**
  String get playerRowWaitingRoster;

  /// No description provided for @timerSemanticsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Timer, {seconds} seconds remaining'**
  String timerSemanticsRemaining(int seconds);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
