import 'package:equatable/equatable.dart';

import 'package:guesstogether/features/game/domain/game_models.dart';

/// High-level game API abstraction so we can plug different backends.
abstract class GameApi {
  Future<RoomSummary> createRoom(CreateRoomRequest request);
  Future<RoomSummary> joinRoom(
    String code, {
    required String playerName,
    String? password,
  });
  Future<List<RoomSummary>> loadRooms();
  Future<RoomDetails> loadRoom(String roomId);
  Future<void> leaveRoom(String roomId);
  Future<void> startRoom(String roomId);

  Future<ProfileSummary> loadProfile();
  Future<List<LeaderboardEntry>> loadLeaderboard(LeaderboardScope scope);
}

enum LeaderboardScope { global, monthly, daily }

enum RoomLifecycleStatus { waiting, inGame, finished }

class CreateRoomRequest extends Equatable {
  const CreateRoomRequest({
    required this.name,
    required this.password,
    required this.mode,
    required this.topic,
    required this.rounds,
    required this.finalWagerEnabled,
    required this.maxPlayers,
    required this.packageFileName,
  });

  final String name;
  final String password;
  final String mode;
  final String topic;
  final int rounds;
  final bool finalWagerEnabled;
  final int maxPlayers;
  final String packageFileName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'password': password,
        'mode': mode,
        'topic': topic,
        'rounds': rounds,
        'finalWagerEnabled': finalWagerEnabled,
        'maxPlayers': maxPlayers,
        'packageFileName': packageFileName,
      };

  @override
  List<Object?> get props => <Object?>[
        name,
        password,
        mode,
        topic,
        rounds,
        finalWagerEnabled,
        maxPlayers,
        packageFileName,
      ];
}

class RoomSummary extends Equatable {
  const RoomSummary({
    required this.id,
    required this.code,
    required this.name,
    required this.topic,
    required this.rounds,
    required this.mode,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.requiresPassword,
    required this.lifecycleStatus,
    required this.isHost,
  });

  final String id;
  final String code;
  final String name;
  final String topic;
  final int rounds;
  final String mode;
  final int currentPlayers;
  final int maxPlayers;
  final bool requiresPassword;
  final RoomLifecycleStatus lifecycleStatus;
  final bool isHost;

  bool get canStartMatch => currentPlayers >= 2;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'code': code,
        'name': name,
        'topic': topic,
        'rounds': rounds,
        'mode': mode,
        'currentPlayers': currentPlayers,
        'maxPlayers': maxPlayers,
        'requiresPassword': requiresPassword,
        'lifecycleStatus': lifecycleStatus.name,
        'isHost': isHost,
      };

  factory RoomSummary.fromJson(Map<String, dynamic> json) {
    return RoomSummary(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      rounds: (json['rounds'] as num?)?.toInt() ?? 0,
      mode: json['mode'] as String? ?? 'multiplayer',
      currentPlayers: (json['currentPlayers'] as num?)?.toInt() ?? 0,
      maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 0,
      requiresPassword: json['requiresPassword'] as bool? ?? false,
      lifecycleStatus: RoomLifecycleStatus.values.firstWhere(
        (RoomLifecycleStatus value) =>
            value.name == (json['lifecycleStatus'] as String? ?? ''),
        orElse: () => RoomLifecycleStatus.waiting,
      ),
      isHost: json['isHost'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        code,
        name,
        topic,
        rounds,
        mode,
        currentPlayers,
        maxPlayers,
        requiresPassword,
        lifecycleStatus,
        isHost,
      ];
}

class RoomParticipant extends Equatable {
  const RoomParticipant({
    required this.id,
    required this.displayName,
    required this.isHost,
    required this.isConnected,
  });

  final String id;
  final String displayName;
  final bool isHost;
  final bool isConnected;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'displayName': displayName,
        'isHost': isHost,
        'isConnected': isConnected,
      };

  factory RoomParticipant.fromJson(Map<String, dynamic> json) {
    return RoomParticipant(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      isHost: json['isHost'] as bool? ?? false,
      isConnected: json['isConnected'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, displayName, isHost, isConnected];
}

class RoomDetails extends Equatable {
  const RoomDetails({
    required this.summary,
    required this.hostPlayerId,
    required this.roomPassword,
    required this.packageFileName,
    required this.participants,
    this.gameState,
  });

  final RoomSummary summary;
  final String hostPlayerId;
  final String roomPassword;
  final String packageFileName;
  final List<RoomParticipant> participants;
  final GameState? gameState;

  RoomParticipant? get hostParticipant {
    for (final RoomParticipant participant in participants) {
      if (participant.isHost) {
        return participant;
      }
    }
    return null;
  }

  List<RoomParticipant> get playerParticipants => participants
      .where((RoomParticipant participant) => !participant.isHost)
      .toList(growable: false);

  Map<String, dynamic> toJson() => <String, dynamic>{
        ...summary.toJson(),
        'hostPlayerId': hostPlayerId,
        'roomPassword': roomPassword,
        'packageFileName': packageFileName,
        'gameState': gameState?.toJson(),
        'participants': participants
            .map((RoomParticipant participant) => participant.toJson())
            .toList(),
      };

  factory RoomDetails.fromJson(Map<String, dynamic> json) {
    return RoomDetails(
      summary: RoomSummary.fromJson(json),
      hostPlayerId: json['hostPlayerId'] as String? ?? '',
      roomPassword: json['roomPassword'] as String? ?? '',
      packageFileName: json['packageFileName'] as String? ?? '',
      gameState: json['gameState'] is Map<String, dynamic>
          ? GameState.fromJson(json['gameState'] as Map<String, dynamic>)
          : null,
      participants: ((json['participants'] as List<dynamic>? ?? <dynamic>[]))
          .map(
            (dynamic item) =>
                RoomParticipant.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        summary,
        hostPlayerId,
        roomPassword,
        packageFileName,
        gameState,
        participants,
      ];
}

class ProfileSummary extends Equatable {
  const ProfileSummary({
    required this.displayName,
    required this.gamesPlayed,
    required this.winRate,
    required this.bestScore,
    this.wins = 0,
    this.losses = 0,
    this.totalXp = 0,
    this.clutchCorrectAnswers = 0,
    this.unlockedAchievementIds = const <String>[],
    this.recentGames = const <ProfileRecentGame>[],
  });

  final String displayName;
  final int gamesPlayed;
  final double winRate;
  final int bestScore;
  final int wins;
  final int losses;
  final int totalXp;
  final int clutchCorrectAnswers;
  final List<String> unlockedAchievementIds;
  final List<ProfileRecentGame> recentGames;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'displayName': displayName,
        'gamesPlayed': gamesPlayed,
        'winRate': winRate,
        'bestScore': bestScore,
        'wins': wins,
        'losses': losses,
        'totalXp': totalXp,
        'clutchCorrectAnswers': clutchCorrectAnswers,
        'unlockedAchievementIds': unlockedAchievementIds,
        'recentGames':
            recentGames.map((ProfileRecentGame game) => game.toJson()).toList(),
      };

  factory ProfileSummary.fromJson(Map<String, dynamic> json) {
    return ProfileSummary(
      displayName: json['displayName'] as String? ?? '',
      gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0,
      bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      clutchCorrectAnswers:
          (json['clutchCorrectAnswers'] as num?)?.toInt() ?? 0,
      unlockedAchievementIds:
          (json['unlockedAchievementIds'] as List<dynamic>? ?? <dynamic>[])
              .map((dynamic item) => item as String)
              .toList(growable: false),
      recentGames: (json['recentGames'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) =>
              ProfileRecentGame.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        displayName,
        gamesPlayed,
        winRate,
        bestScore,
        wins,
        losses,
        totalXp,
        clutchCorrectAnswers,
        unlockedAchievementIds,
        recentGames,
      ];
}

class ProfileRecentGame extends Equatable {
  const ProfileRecentGame({
    required this.roomName,
    required this.won,
    required this.mode,
    required this.playedAtEpochMs,
    this.score,
    this.wasHost = false,
  });

  final String roomName;
  final int? score;
  final bool won;
  final String mode;
  final int playedAtEpochMs;
  final bool wasHost;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'roomName': roomName,
        'score': score,
        'won': won,
        'mode': mode,
        'playedAtEpochMs': playedAtEpochMs,
        'wasHost': wasHost,
      };

  factory ProfileRecentGame.fromJson(Map<String, dynamic> json) {
    return ProfileRecentGame(
      roomName: json['roomName'] as String? ?? '',
      score: (json['score'] as num?)?.toInt(),
      won: json['won'] as bool? ?? false,
      mode: json['mode'] as String? ?? 'multiplayer',
      playedAtEpochMs: (json['playedAtEpochMs'] as num?)?.toInt() ?? 0,
      wasHost: json['wasHost'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[roomName, score, won, mode, playedAtEpochMs, wasHost];
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'rank': rank,
        'playerName': playerName,
        'score': score,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      playerName: json['playerName'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => <Object?>[rank, playerName, score];
}
