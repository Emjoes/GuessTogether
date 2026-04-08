import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/lobby/providers/create_room_provider.dart';

class _FakeGameApi implements GameApi {
  CreateRoomRequest? lastCreateRoomRequest;

  @override
  Future<RoomSummary> createRoom(CreateRoomRequest request) async {
    lastCreateRoomRequest = request;
    return RoomSummary(
      id: '1',
      code: '1234',
      name: request.name,
      topic: request.topic,
      rounds: request.rounds,
      mode: request.mode,
      currentPlayers: 1,
      maxPlayers: request.maxPlayers,
      requiresPassword: request.password.isNotEmpty,
      lifecycleStatus: RoomLifecycleStatus.waiting,
      isHost: true,
    );
  }

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard(
          LeaderboardScope scope) async =>
      <LeaderboardEntry>[];

  @override
  Future<ProfileSummary> loadProfile() async => const ProfileSummary(
        displayName: 'x',
        gamesPlayed: 0,
        winRate: 0,
        bestScore: 0,
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
        packageFileName: defaultRoomPackageFileName,
        participants: <RoomParticipant>[],
      );

  @override
  Future<void> leaveRoom(String roomId) async {}

  @override
  Future<void> startRoom(String roomId) async {}
}

void main() {
  test('CreateRoomController clamps players to 2..4', () async {
    final c = CreateRoomController(_FakeGameApi());
    c.setPlayers(-5);
    expect(c.state.players, 2);
    c.setPlayers(999);
    expect(c.state.players, 4);
  });

  test('CreateRoomController forces 2 players in duel mode', () async {
    final c = CreateRoomController(_FakeGameApi());
    c.setPlayers(4);
    c.setMode(RoomMode.duel);
    expect(c.state.players, 2);
  });

  test('CreateRoomController stores selected package file name', () async {
    final c = CreateRoomController(_FakeGameApi());
    c.setPackageFileName('general_quiz_pack.json');
    expect(c.state.packageFileName, 'general_quiz_pack.json');
  });

  test('CreateRoomController uses standard package and three rounds', () async {
    final _FakeGameApi api = _FakeGameApi();
    final c = CreateRoomController(api);

    expect(c.state.packageFileName, defaultRoomPackageFileName);
    await c.createRoom();

    expect(api.lastCreateRoomRequest?.rounds, 3);
    expect(
      api.lastCreateRoomRequest?.packageFileName,
      defaultRoomPackageFileName,
    );
  });
}
