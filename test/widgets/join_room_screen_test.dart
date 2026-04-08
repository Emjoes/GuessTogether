import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/lobby/presentation/join_room_screen.dart';
import 'package:guesstogether/features/session/app_session_controller.dart';
import '../test_app.dart';

class _FakeJoinRoomsApi implements GameApi {
  @override
  Future<List<RoomSummary>> loadRooms() async => const <RoomSummary>[
        RoomSummary(
          id: 'room-1001',
          code: '1001',
          name: 'Friday Trivia Crew',
          topic: 'General',
          rounds: 3,
          mode: 'multiplayer',
          currentPlayers: 3,
          maxPlayers: 4,
          requiresPassword: true,
          lifecycleStatus: RoomLifecycleStatus.waiting,
          isHost: false,
        ),
        RoomSummary(
          id: 'room-8890',
          code: '8890',
          name: 'Movie Legends',
          topic: 'Movies',
          rounds: 3,
          mode: 'multiplayer',
          currentPlayers: 2,
          maxPlayers: 4,
          requiresPassword: false,
          lifecycleStatus: RoomLifecycleStatus.waiting,
          isHost: false,
        ),
      ];

  @override
  Future<RoomSummary> joinRoom(
    String code, {
    required String playerName,
    String? password,
  }) async =>
      RoomSummary(
        id: 'room-$code',
        code: code,
        name: 'Room $code',
        topic: 'General',
        rounds: 3,
        mode: 'multiplayer',
        currentPlayers: 2,
        maxPlayers: 4,
        requiresPassword: false,
        lifecycleStatus: RoomLifecycleStatus.waiting,
        isHost: false,
      );

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
  Future<ProfileSummary> loadProfile() async => const ProfileSummary(
        displayName: 'x',
        gamesPlayed: 0,
        winRate: 0,
        bestScore: 0,
      );

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard(
    LeaderboardScope scope,
  ) async =>
      <LeaderboardEntry>[];

  @override
  Future<RoomDetails> loadRoom(String roomId) async => const RoomDetails(
        summary: RoomSummary(
          id: 'room-1001',
          code: '1001',
          name: 'Friday Trivia Crew',
          topic: 'General',
          rounds: 3,
          mode: 'multiplayer',
          currentPlayers: 3,
          maxPlayers: 4,
          requiresPassword: true,
          lifecycleStatus: RoomLifecycleStatus.waiting,
          isHost: false,
        ),
        hostPlayerId: 'host',
        roomPassword: '4321',
        packageFileName: '',
        participants: <RoomParticipant>[],
      );

  @override
  Future<void> leaveRoom(String roomId) async {}

  @override
  Future<void> startRoom(String roomId) async {}
}

void main() {
  testWidgets('JoinRoomScreen shows active lobbies table', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameApiProvider.overrideWithValue(_FakeJoinRoomsApi()),
        ],
        child: const _JoinRoomApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(AppStrings.joinRoomSearchLabel), findsNothing);
    expect(find.text('Room name'), findsOneWidget);
    expect(find.text('Cool Quiz'), findsOneWidget);
    expect(find.text(AppStrings.joinRoomActiveLobbies), findsOneWidget);
    expect(find.text(AppStrings.joinRoomTableRoom), findsNothing);
    expect(find.text(AppStrings.joinRoomTablePlayers), findsNothing);
    expect(find.text(AppStrings.joinRoomTableType), findsNothing);
    expect(find.text(AppStrings.joinRoomTablePassword), findsNothing);
    expect(find.text('Friday Trivia Crew'), findsOneWidget);
    expect(find.text('#1001'), findsOneWidget);
    expect(
      tester.widget<AppBar>(find.byType(AppBar)).actionsPadding,
      const EdgeInsetsDirectional.only(end: 8),
    );
  });

  testWidgets('JoinRoomScreen filters rooms by name', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameApiProvider.overrideWithValue(_FakeJoinRoomsApi()),
        ],
        child: const _JoinRoomApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Friday Trivia Crew'), findsOneWidget);
    expect(find.text('Movie Legends'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'movie');
    await tester.pumpAndSettle();

    expect(find.text('Friday Trivia Crew'), findsNothing);
    expect(find.text('Movie Legends'), findsOneWidget);
  });

  testWidgets('JoinRoomScreen filters rooms by code', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameApiProvider.overrideWithValue(_FakeJoinRoomsApi()),
        ],
        child: const _JoinRoomApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Friday Trivia Crew'), findsOneWidget);
    expect(find.text('Movie Legends'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '1001');
    await tester.pumpAndSettle();

    expect(find.text('Friday Trivia Crew'), findsOneWidget);
    expect(find.text('Movie Legends'), findsNothing);
  });

  testWidgets('JoinRoomScreen opens password dialog safely', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameApiProvider.overrideWithValue(_FakeJoinRoomsApi()),
        ],
        child: const _JoinRoomApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Friday Trivia Crew'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.joinRoomPasswordDialogTitle), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.joinRoomPasswordDialogTitle), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _JoinRoomApp extends StatelessWidget {
  const _JoinRoomApp();

  @override
  Widget build(BuildContext context) {
    return buildTestMaterialApp(
      home: const JoinRoomScreen(),
      locale: const Locale('en'),
    );
  }
}
