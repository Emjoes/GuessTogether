import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/lobby/providers/join_room_provider.dart';

class _FakeJoinApi implements GameApi {
  _FakeJoinApi({this.shouldFailJoin = false});

  bool shouldFailJoin;

  @override
  Future<RoomSummary> joinRoom(
    String code, {
    required String playerName,
    String? password,
  }) async {
    if (shouldFailJoin) {
      throw Exception('join failed');
    }
    if (code == '1001' && (password ?? '') != '4321') {
      throw Exception('wrong password');
    }
    return RoomSummary(
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
  test(
      'JoinRoomController returns wrong_password when backend rejects password',
      () async {
    final JoinRoomController controller = JoinRoomController(_FakeJoinApi());
    await controller.refreshRooms();
    final RoomSummary protectedRoom = controller.state.rooms
        .firstWhere((RoomSummary room) => room.requiresPassword);

    await expectLater(
      () => controller.joinLobby(
        protectedRoom,
        password: 'bad',
      ),
      throwsException,
    );

    expect(controller.state.joinErrorText, 'wrong_password');
    expect(controller.state.isLoading, false);
  });

  test('JoinRoomController joins open lobby without password', () async {
    final JoinRoomController controller = JoinRoomController(_FakeJoinApi());
    await controller.refreshRooms();
    final RoomSummary openRoom = controller.state.rooms
        .firstWhere((RoomSummary room) => !room.requiresPassword);

    final RoomSummary result = await controller.joinLobby(openRoom);

    expect(result.code, openRoom.code);
    expect(controller.state.joinErrorText, isNull);
    expect(controller.state.isLoading, false);
    expect(controller.state.joiningRoomId, isNull);
  });

  test('JoinRoomController stores invalid error when api throws', () async {
    final JoinRoomController controller =
        JoinRoomController(_FakeJoinApi(shouldFailJoin: true));
    await controller.refreshRooms();
    final RoomSummary openRoom = controller.state.rooms
        .firstWhere((RoomSummary room) => !room.requiresPassword);

    await expectLater(
      () => controller.joinLobby(openRoom),
      throwsException,
    );

    expect(controller.state.joinErrorText, 'invalid');
    expect(controller.state.isLoading, false);
  });
}
