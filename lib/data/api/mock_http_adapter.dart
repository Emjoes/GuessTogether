import 'dart:math';

import 'package:guesstogether/core/constants/question_packages.dart';
import 'package:guesstogether/core/debug/loading_debug_gate.dart';
import 'package:guesstogether/data/api/game_api.dart';

/// Very small mock HTTP adapter that returns static data.
class MockHttpAdapter implements GameApi {
  MockHttpAdapter();

  final Random _random = Random();

  @override
  Future<RoomSummary> createRoom(CreateRoomRequest request) async {
    await LoadingDebugGate.instance.delayed(const Duration(milliseconds: 400));
    final id = _random.nextInt(999999).toString();
    final code = id.padLeft(4, '0').substring(0, 4);
    return RoomSummary(
      id: id,
      code: code,
      name: request.name.isEmpty ? 'Guess Together Room' : request.name,
      topic: request.topic.isEmpty ? 'General Trivia' : request.topic,
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
  Future<RoomSummary> joinRoom(
    String code, {
    required String playerName,
    String? password,
  }) async {
    await LoadingDebugGate.instance.delayed(const Duration(milliseconds: 300));
    if (code.length < 4) {
      throw Exception('Room not found');
    }
    return RoomSummary(
      id: 'room-$code',
      code: code,
      name: 'Room $code',
      topic: 'General Trivia',
      rounds: 3,
      mode: 'multiplayer',
      currentPlayers: 2,
      maxPlayers: 4,
      requiresPassword: (password ?? '').isNotEmpty,
      lifecycleStatus: RoomLifecycleStatus.waiting,
      isHost: false,
    );
  }

  @override
  Future<List<RoomSummary>> loadRooms() async {
    await LoadingDebugGate.instance.delayed(const Duration(milliseconds: 220));
    return const <RoomSummary>[
      RoomSummary(
        id: 'room-1001',
        code: '1001',
        name: 'Friday Trivia Crew',
        topic: 'General Trivia',
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
  }

  @override
  Future<RoomDetails> loadRoom(String roomId) async {
    await LoadingDebugGate.instance.delayed(const Duration(milliseconds: 180));
    return const RoomDetails(
      summary: RoomSummary(
        id: 'room-1001',
        code: '1001',
        name: 'Friday Trivia Crew',
        topic: 'General Trivia',
        rounds: 3,
        mode: 'multiplayer',
        currentPlayers: 3,
        maxPlayers: 4,
        requiresPassword: true,
        lifecycleStatus: RoomLifecycleStatus.waiting,
        isHost: true,
      ),
      hostPlayerId: 'p1',
      roomPassword: '4321',
      packageFileName: standardQuestionPackFileName,
      participants: <RoomParticipant>[
        RoomParticipant(
          id: 'p1',
          displayName: 'Serge',
          isHost: true,
          isConnected: true,
        ),
        RoomParticipant(
          id: 'p2',
          displayName: 'Ivy',
          isHost: false,
          isConnected: true,
        ),
        RoomParticipant(
          id: 'p3',
          displayName: 'Max',
          isHost: false,
          isConnected: false,
        ),
      ],
    );
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    await LoadingDebugGate.instance.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<void> startRoom(String roomId) async {
    await LoadingDebugGate.instance.delayed(const Duration(milliseconds: 140));
  }

  @override
  Future<ProfileSummary> loadProfile() async {
    await LoadingDebugGate.instance.delayed(const Duration(milliseconds: 250));
    return const ProfileSummary(
      displayName: 'Player One',
      gamesPlayed: 42,
      winRate: 0.57,
      bestScore: 9800,
      wins: 24,
      losses: 18,
      totalXp: 3320,
      clutchCorrectAnswers: 1,
      unlockedAchievementIds: <String>['first_win', 'clutch_answer'],
      recentGames: <ProfileRecentGame>[
        ProfileRecentGame(
          roomName: 'Friday Trivia Crew',
          score: 5200,
          won: true,
          mode: 'multiplayer',
          playedAtEpochMs: 1730404800000,
        ),
        ProfileRecentGame(
          roomName: 'Movie Legends',
          won: false,
          mode: 'duel',
          playedAtEpochMs: 1730318400000,
          wasHost: true,
        ),
      ],
    );
  }

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard(LeaderboardScope scope) async {
    await LoadingDebugGate.instance.delayed(const Duration(milliseconds: 250));
    return List<LeaderboardEntry>.generate(
      10,
      (int i) => LeaderboardEntry(
        rank: i + 1,
        playerName: '${scope.name} Player ${i + 1}',
        score: 28 - i,
      ),
    );
  }
}
