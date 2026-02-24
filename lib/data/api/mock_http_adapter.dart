import 'dart:math';

import 'package:guesstogether/data/api/game_api.dart';

/// Very small mock HTTP adapter that returns static data.
class MockHttpAdapter implements GameApi {
  MockHttpAdapter();

  final Random _random = Random();

  @override
  Future<RoomSummary> createRoom(CreateRoomRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final id = _random.nextInt(999999).toString();
    final code = id.padLeft(4, '0').substring(0, 4);
    return RoomSummary(
      id: id,
      code: code,
      name: request.name.isEmpty ? 'Guess Together Room' : request.name,
      topic: request.topic.isEmpty ? 'General Trivia' : request.topic,
      rounds: request.rounds,
    );
  }

  @override
  Future<RoomSummary> joinRoom(String code,
      {required String playerName}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (code.length < 4) {
      throw Exception('Room not found');
    }
    return RoomSummary(
      id: 'room-$code',
      code: code,
      name: 'Room $code',
      topic: 'General Trivia',
      rounds: 3,
    );
  }

  @override
  Future<ProfileSummary> loadProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const ProfileSummary(
      displayName: 'Player One',
      gamesPlayed: 42,
      winRate: 0.57,
      bestScore: 9800,
    );
  }

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard(LeaderboardScope scope) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List<LeaderboardEntry>.generate(
      10,
      (int i) => LeaderboardEntry(
        rank: i + 1,
        playerName: '${scope.name} Player ${i + 1}',
        score: 12000 - i * 500,
      ),
    );
  }
}
