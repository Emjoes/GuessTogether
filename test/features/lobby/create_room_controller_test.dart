import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/lobby/providers/create_room_provider.dart';

class _FakeGameApi implements GameApi {
  @override
  Future<RoomSummary> createRoom(CreateRoomRequest request) async {
    return RoomSummary(
      id: '1',
      code: '1234',
      name: request.name,
      topic: request.topic,
      rounds: request.rounds,
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
  Future<RoomSummary> joinRoom(String code,
          {required String playerName}) async =>
      const RoomSummary(
        id: '1',
        code: '1234',
        name: 'Room',
        topic: 'Topic',
        rounds: 3,
      );
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
}
