import 'package:equatable/equatable.dart';

/// High-level game API abstraction so we can plug different backends.
abstract class GameApi {
  Future<RoomSummary> createRoom(CreateRoomRequest request);
  Future<RoomSummary> joinRoom(String code, {required String playerName});

  Future<ProfileSummary> loadProfile();
  Future<List<LeaderboardEntry>> loadLeaderboard(LeaderboardScope scope);
}

enum LeaderboardScope { global, friends, weekly }

class CreateRoomRequest extends Equatable {
  const CreateRoomRequest({
    required this.name,
    required this.mode,
    required this.topic,
    required this.rounds,
    required this.finalWagerEnabled,
  });

  final String name;
  final String mode;
  final String topic;
  final int rounds;
  final bool finalWagerEnabled;

  @override
  List<Object?> get props =>
      <Object?>[name, mode, topic, rounds, finalWagerEnabled];
}

class RoomSummary extends Equatable {
  const RoomSummary({
    required this.id,
    required this.code,
    required this.name,
    required this.topic,
    required this.rounds,
  });

  final String id;
  final String code;
  final String name;
  final String topic;
  final int rounds;

  @override
  List<Object?> get props => <Object?>[id, code, name, topic, rounds];
}

class ProfileSummary extends Equatable {
  const ProfileSummary({
    required this.displayName,
    required this.gamesPlayed,
    required this.winRate,
    required this.bestScore,
  });

  final String displayName;
  final int gamesPlayed;
  final double winRate;
  final int bestScore;

  @override
  List<Object?> get props =>
      <Object?>[displayName, gamesPlayed, winRate, bestScore];
}

class LeaderboardEntry extends Equatable {
  const LeaderboardEntry({
    required this.rank,
    required this.playerName,
    required this.score,
  });

  final int rank;
  final String playerName;
  final int score;

  @override
  List<Object?> get props => <Object?>[rank, playerName, score];
}
