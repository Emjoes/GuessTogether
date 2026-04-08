import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/profile/presentation/profile_screen.dart';
import 'package:guesstogether/features/session/app_session_controller.dart';
import '../test_app.dart';

class _FakeProfileApi implements GameApi {
  int leaderboardCalls = 0;

  @override
  Future<ProfileSummary> loadProfile() async => ProfileSummary(
        displayName: 'Player One',
        gamesPlayed: 13,
        winRate: 0.5,
        bestScore: 4200,
        wins: 7,
        losses: 5,
        totalXp: 1640,
        clutchCorrectAnswers: 1,
        recentGames: <ProfileRecentGame>[
          ProfileRecentGame(
            roomName: 'Friday Trivia Crew',
            score: 4200,
            won: true,
            mode: 'multiplayer',
            playedAtEpochMs: DateTime(2024, 11, 1).millisecondsSinceEpoch,
          ),
          ProfileRecentGame(
            roomName: 'Movie Legends',
            won: false,
            mode: 'duel',
            playedAtEpochMs: DateTime(2024, 10, 31).millisecondsSinceEpoch,
            wasHost: true,
          ),
        ],
      );

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard(
    LeaderboardScope scope,
  ) async {
    leaderboardCalls += 1;
    return <LeaderboardEntry>[
      LeaderboardEntry(rank: 1, playerName: '${scope.name} Player 1', score: 9),
      LeaderboardEntry(rank: 2, playerName: '${scope.name} Player 2', score: 7),
    ];
  }

  @override
  Future<RoomSummary> createRoom(CreateRoomRequest request) async =>
      const RoomSummary(
        id: '1',
        code: '1234',
        name: 'Room',
        topic: 'Topic',
        rounds: 3,
        mode: 'multiplayer',
        currentPlayers: 1,
        maxPlayers: 4,
        requiresPassword: false,
        lifecycleStatus: RoomLifecycleStatus.waiting,
        isHost: true,
      );

  @override
  Future<RoomSummary> joinRoom(
    String code, {
    required String playerName,
    String? password,
  }) async =>
      const RoomSummary(
        id: '1',
        code: '1234',
        name: 'Room',
        topic: 'Topic',
        rounds: 3,
        mode: 'multiplayer',
        currentPlayers: 2,
        maxPlayers: 4,
        requiresPassword: false,
        lifecycleStatus: RoomLifecycleStatus.waiting,
        isHost: false,
      );

  @override
  Future<List<RoomSummary>> loadRooms() async => <RoomSummary>[];

  @override
  Future<RoomDetails> loadRoom(String roomId) async => const RoomDetails(
        summary: RoomSummary(
          id: '1',
          code: '1234',
          name: 'Room',
          topic: 'Topic',
          rounds: 3,
          mode: 'multiplayer',
          currentPlayers: 2,
          maxPlayers: 4,
          requiresPassword: false,
          lifecycleStatus: RoomLifecycleStatus.waiting,
          isHost: true,
        ),
        hostPlayerId: '1',
        roomPassword: '',
        packageFileName: '',
        participants: <RoomParticipant>[],
      );

  @override
  Future<void> leaveRoom(String roomId) async {}

  @override
  Future<void> startRoom(String roomId) async {}
}

class _HostedOnlyProfileApi implements GameApi {
  @override
  Future<ProfileSummary> loadProfile() async => ProfileSummary(
        displayName: 'Host Player',
        gamesPlayed: 4,
        winRate: 0,
        bestScore: 0,
        wins: 0,
        losses: 0,
        totalXp: 0,
        recentGames: <ProfileRecentGame>[
          ProfileRecentGame(
            roomName: 'Hosted Match',
            won: false,
            mode: 'multiplayer',
            playedAtEpochMs: DateTime(2024, 11, 1).millisecondsSinceEpoch,
            wasHost: true,
          ),
        ],
      );

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard(
    LeaderboardScope scope,
  ) async =>
      <LeaderboardEntry>[];

  @override
  Future<RoomSummary> createRoom(CreateRoomRequest request) async =>
      throw UnimplementedError();

  @override
  Future<RoomSummary> joinRoom(
    String code, {
    required String playerName,
    String? password,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<RoomSummary>> loadRooms() async => <RoomSummary>[];

  @override
  Future<RoomDetails> loadRoom(String roomId) async =>
      throw UnimplementedError();

  @override
  Future<void> leaveRoom(String roomId) async {}

  @override
  Future<void> startRoom(String roomId) async {}
}

void main() {
  testWidgets('ProfileScreen shows tabbed profile sections',
      (WidgetTester tester) async {
    final _FakeProfileApi api = _FakeProfileApi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameApiProvider.overrideWithValue(api),
        ],
        child: const _ProfileApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(api.leaderboardCalls, 1);

    expect(find.byTooltip(AppStrings.profileTabStats), findsOneWidget);
    expect(find.byTooltip(AppStrings.profileTabLeaderboards), findsOneWidget);
    expect(find.byTooltip(AppStrings.profileTabAchievements), findsOneWidget);
    expect(find.text(AppStrings.profileStatsLabel), findsOneWidget);
    expect(find.text(AppStrings.profileRecentGames), findsOneWidget);
    expect(find.text('Friday Trivia Crew'), findsOneWidget);
    expect(find.text('Movie Legends'), findsOneWidget);
    expect(find.textContaining('01.11.24'), findsOneWidget);
    expect(find.textContaining('31.10.24'), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.text('2700'), findsNothing);
    expect(find.text('13'), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.profileTabLeaderboards));
    await tester.pumpAndSettle();
    expect(api.leaderboardCalls, 2);
    expect(find.text(AppStrings.profileLeaderboards), findsOneWidget);
    expect(find.text('global Player 1'), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.profileTabAchievements));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.profileAchievements), findsWidgets);
    expect(find.text('First Win'), findsOneWidget);
    expect(find.text('Clutch Answer'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(find.text('7 / 1'), findsNothing);
    expect(find.text('1 / 1'), findsNWidgets(2));
  });

  testWidgets('ProfileScreen does not derive losses from hosted matches only',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameApiProvider.overrideWithValue(_HostedOnlyProfileApi()),
        ],
        child: const _ProfileApp(),
      ),
    );

    await tester.pumpAndSettle();

    final Finder lossesCard = find.byWidgetPredicate((Widget widget) {
      if (widget is! Column || widget.children.length != 5) {
        return false;
      }
      final Widget valueWidget = widget.children[2];
      final Widget labelWidget = widget.children[4];
      return valueWidget is Text &&
          valueWidget.data == '0' &&
          labelWidget is Text &&
          labelWidget.data == AppStrings.profileLosses;
    });

    expect(lossesCard, findsOneWidget);
  });
}

class _ProfileApp extends StatelessWidget {
  const _ProfileApp();

  @override
  Widget build(BuildContext context) {
    return buildTestMaterialApp(
      home: const ProfileScreen(),
      locale: const Locale('en'),
    );
  }
}
