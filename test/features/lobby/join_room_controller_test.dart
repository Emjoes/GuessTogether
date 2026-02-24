import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/lobby/providers/join_room_provider.dart';

class _FakeJoinApi implements GameApi {
  _FakeJoinApi({this.shouldFailJoin = false});

  bool shouldFailJoin;

  @override
  Future<RoomSummary> joinRoom(String code, {required String playerName}) async {
    if (shouldFailJoin) {
      throw Exception('join failed');
    }
    return RoomSummary(
      id: 'room-$code',
      code: code,
      name: 'Room $code',
      topic: 'General',
      rounds: 3,
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
      );

  @override
  Future<ProfileSummary> loadProfile() async => const ProfileSummary(
        displayName: 'x',
        gamesPlayed: 0,
        winRate: 0,
        bestScore: 0,
      );

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard(LeaderboardScope scope) async =>
      <LeaderboardEntry>[];
}

void main() {
  test('JoinRoomController returns invalidPassword for protected lobby', () async {
    final controller = JoinRoomController(_FakeJoinApi());
    final LobbyRoom protectedRoom =
        controller.state.rooms.firstWhere((LobbyRoom room) => room.requiresPassword);

    final JoinLobbyResult result = await controller.joinLobby(
      protectedRoom,
      password: 'bad',
    );

    expect(result, JoinLobbyResult.invalidPassword);
    expect(controller.state.errorText, 'wrong_password');
    expect(controller.state.isLoading, false);
  });

  test('JoinRoomController joins open lobby without password', () async {
    final controller = JoinRoomController(_FakeJoinApi());
    final LobbyRoom openRoom =
        controller.state.rooms.firstWhere((LobbyRoom room) => !room.requiresPassword);

    final JoinLobbyResult result = await controller.joinLobby(openRoom);

    expect(result, JoinLobbyResult.success);
    expect(controller.state.errorText, isNull);
    expect(controller.state.isLoading, false);
    expect(controller.state.joiningRoomId, isNull);
  });

  test('JoinRoomController returns failed when api throws', () async {
    final controller = JoinRoomController(_FakeJoinApi(shouldFailJoin: true));
    final LobbyRoom openRoom =
        controller.state.rooms.firstWhere((LobbyRoom room) => !room.requiresPassword);

    final JoinLobbyResult result = await controller.joinLobby(openRoom);

    expect(result, JoinLobbyResult.failed);
    expect(controller.state.errorText, 'invalid');
    expect(controller.state.isLoading, false);
  });
}
