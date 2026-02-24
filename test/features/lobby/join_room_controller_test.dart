import 'package:flutter_test/flutter_test.dart';
import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/lobby/providers/join_room_provider.dart';

class _FailingJoinApi implements GameApi {
  @override
  Future<RoomSummary> joinRoom(String code, {required String playerName}) async {
    throw Exception('not found');
  }

  @override
  Future<RoomSummary> createRoom(CreateRoomRequest request) async =>
      const RoomSummary(id: '1', code: '1234', name: 'Room', topic: 'Topic', rounds: 3);

  @override
  Future<ProfileSummary> loadProfile() async =>
      const ProfileSummary(displayName: 'x', gamesPlayed: 0, winRate: 0, bestScore: 0);

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard(LeaderboardScope scope) async =>
      <LeaderboardEntry>[];
}

void main() {
  test('JoinRoomController sets errorText on join failure', () async {
    final controller = JoinRoomController(_FailingJoinApi());
    controller.setCode('12');
    await controller.submit();
    expect(controller.state.errorText, isNotNull);
    expect(controller.state.isLoading, false);
  });
}

