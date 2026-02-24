import 'package:flutter_test/flutter_test.dart';
import 'package:guesstogether/features/lobby/providers/create_room_provider.dart';
import 'package:guesstogether/data/api/game_api.dart';

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
  Future<List<LeaderboardEntry>> loadLeaderboard(LeaderboardScope scope) async =>
      <LeaderboardEntry>[];

  @override
  Future<ProfileSummary> loadProfile() async =>
      const ProfileSummary(displayName: 'x', gamesPlayed: 0, winRate: 0, bestScore: 0);

  @override
  Future<RoomSummary> joinRoom(String code, {required String playerName}) async =>
      const RoomSummary(id: '1', code: '1234', name: 'Room', topic: 'Topic', rounds: 3);
}

void main() {
  test('CreateRoomController clamps rounds to 1..10', () async {
    final c = CreateRoomController(_FakeGameApi());
    c.setRounds(-5);
    expect(c.state.rounds, 1);
    c.setRounds(999);
    expect(c.state.rounds, 10);
  });
}

