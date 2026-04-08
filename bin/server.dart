import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:guesstogether/data/api/backend_models.dart';
import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/game/domain/game_models.dart';
import 'package:guesstogether/features/game/domain/game_state_machine.dart';

const String _defaultDatabaseUrl =
    'postgresql://postgres:postgres@localhost:5432/'
    'guesstogether?sslmode=disable';

Future<void> main() async {
  try {
    final AppServer server = AppServer.fromEnvironment();
    await server.start();
  } catch (error) {
    stderr.writeln(
      'Failed to start backend. Ensure PostgreSQL is running and '
      'DATABASE_URL or POSTGRES_* settings are correct.',
    );
    stderr.writeln(error);
    exitCode = 1;
  }
}

const String _firstWinAchievementId = 'first_win';
const String _clutchAnswerAchievementId = 'clutch_answer';
const int _recentMatchesLimit = 8;

bool shouldApplyMatchProfileUpdates({
  required GameState? previousState,
  required GameState nextState,
  required StoredMatchProgress matchProgress,
}) {
  final bool matchJustEnded =
      !(previousState?.isMatchEnded ?? false) && nextState.isMatchEnded;
  if (!matchJustEnded || matchProgress.profileApplied) {
    return false;
  }
  return !matchProgress.endedByAbandonment;
}

String _databaseUrlFromEnvironment() {
  final String explicitUrl = Platform.environment['DATABASE_URL']?.trim() ?? '';
  if (explicitUrl.isNotEmpty) {
    return explicitUrl;
  }

  final String host =
      (Platform.environment['POSTGRES_HOST'] ?? 'localhost').trim();
  final String port = (Platform.environment['POSTGRES_PORT'] ?? '5432').trim();
  final String database =
      (Platform.environment['POSTGRES_DB'] ?? 'guesstogether').trim();
  final String username =
      (Platform.environment['POSTGRES_USER'] ?? 'postgres').trim();
  final String password =
      Platform.environment['POSTGRES_PASSWORD'] ?? 'postgres';
  final String sslMode =
      (Platform.environment['POSTGRES_SSLMODE'] ?? 'disable').trim();

  return 'postgresql://${Uri.encodeComponent(username)}:'
      '${Uri.encodeComponent(password)}@$host:$port/$database?sslmode=$sslMode';
}

String _serverHostFromEnvironment() {
  final String configured = Platform.environment['SERVER_HOST']?.trim() ?? '';
  return configured.isEmpty ? '127.0.0.1' : configured;
}

int _serverPortFromEnvironment() {
  final String configured = Platform.environment['PORT']?.trim() ?? '';
  return int.tryParse(configured) ?? 8080;
}

class AppServer {
  static const Duration _hostlessRoomGracePeriod = Duration(seconds: 45);
  static const String _defaultPackageFileName = 'general_quiz_pack.json';

  AppServer.fromEnvironment()
      : this(
          host: _serverHostFromEnvironment(),
          port: _serverPortFromEnvironment(),
          databaseUrl: _databaseUrlFromEnvironment(),
        );

  AppServer({
    String host = '127.0.0.1',
    int port = 8080,
    String databaseUrl = _defaultDatabaseUrl,
  })  : _host = host,
        _port = port,
        _store = _AppStateStore(
          databaseUrl: databaseUrl,
          packageRepository: _QuestionPackageRepository(
            packageDirectory: Directory('backend_packages'),
            defaultPackageFileName: _defaultPackageFileName,
          ),
        );

  final String _host;
  final int _port;
  final _AppStateStore _store;
  final Map<String, Map<String, WebSocketChannel>> _roomSockets =
      <String, Map<String, WebSocketChannel>>{};
  Timer? _matchTicker;

  Future<void> start() async {
    await _store.load();
    stdout.writeln('Using PostgreSQL store at ${_store.connectionSummary}');
    _matchTicker?.cancel();
    _matchTicker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(_tickServer()),
    );

    final Router router = Router()
      ..get('/health', _handleHealth)
      ..post('/api/register', _handleRegister)
      ..post('/api/login', _handleLogin)
      ..get('/api/me', _handleMe)
      ..put('/api/me/settings', _handleSaveSettings)
      ..get('/api/leaderboard', _handleLeaderboard)
      ..get('/api/rooms', _handleRooms)
      ..post('/api/rooms', _handleCreateRoom)
      ..post('/api/rooms/join', _handleJoinRoom)
      ..get('/api/rooms/<roomId>', _handleRoomDetails)
      ..post('/api/rooms/<roomId>/leave', _handleLeaveRoom)
      ..post('/api/rooms/<roomId>/start', _handleStartRoom)
      ..post('/api/rooms/<roomId>/game/choose', _handleChooseQuestion)
      ..post('/api/rooms/<roomId>/game/answer', _handleRequestAnswer)
      ..post('/api/rooms/<roomId>/game/pass', _handlePassQuestion)
      ..post('/api/rooms/<roomId>/game/accept', _handleAcceptAnswer)
      ..post('/api/rooms/<roomId>/game/reject', _handleRejectAnswer)
      ..post('/api/rooms/<roomId>/game/pause', _handleTogglePause)
      ..post('/api/rooms/<roomId>/game/skip', _handleSkipQuestion)
      ..post('/api/rooms/<roomId>/game/skip-round', _handleSkipRound)
      ..post('/api/rooms/<roomId>/game/score', _handleSetPlayerScore)
      ..get('/ws/rooms/<roomId>', _handleRoomSocket);

    final Handler handler = const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addMiddleware(logRequests())
        .addHandler(router.call);

    final HttpServer server = await shelf_io.serve(handler, _host, _port);
    stdout.writeln(
      'GuessTogether backend is running on http://${server.address.host}:${server.port}',
    );
  }

  Middleware _corsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return _withCors(Response.ok(''));
        }
        final Response response = await innerHandler(request);
        return _withCors(response);
      };
    };
  }

  Response _withCors(Response response) {
    return response.change(headers: <String, String>{
      ...response.headers,
      'access-control-allow-origin': '*',
      'access-control-allow-methods': 'GET, POST, PUT, OPTIONS',
      'access-control-allow-headers': 'Origin, Content-Type, Authorization',
    });
  }

  Response _json(Object body, {int status = 200}) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: const <String, String>{'content-type': 'application/json'},
    );
  }

  Future<Map<String, dynamic>> _readJson(Request request) async {
    final String body = await request.readAsString();
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final dynamic decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiError(400, 'Invalid JSON body');
    }
    return decoded;
  }

  StoredUser _requireUser(Request request) {
    final String header = request.headers['authorization'] ?? '';
    if (!header.startsWith('Bearer ')) {
      throw const ApiError(401, 'Unauthorized');
    }
    final String token = header.substring('Bearer '.length).trim();
    final StoredUser? user = _store.findUserByToken(token);
    if (user == null) {
      throw const ApiError(401, 'Session expired');
    }
    return user;
  }

  StoredRoom _requireRoom(String roomId) {
    final StoredRoom? room = _store.findRoomById(roomId);
    if (room == null) {
      throw const ApiError(404, 'Room not found');
    }
    return room;
  }

  void _requireRoomMember(StoredRoom room, StoredUser user) {
    if (!room.participants.any(
      (StoredRoomParticipant participant) => participant.userId == user.id,
    )) {
      throw const ApiError(403, 'You are not a member of this room');
    }
  }

  String _normalizeEmail(String value) => value.trim().toLowerCase();

  String _generatedEmailForUserId(String userId) => '$userId@players.local';

  String _hashPassword(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  RoomSummary _roomSummaryForUser(StoredRoom room, StoredUser user) {
    return RoomSummary(
      id: room.id,
      code: room.code,
      name: room.name,
      topic: room.topic,
      rounds: room.rounds,
      mode: room.mode,
      currentPlayers: room.playerCount,
      maxPlayers: room.maxPlayers,
      requiresPassword: room.password.isNotEmpty,
      lifecycleStatus: room.status,
      isHost: room.hostUserId == user.id,
    );
  }

  RoomDetails _roomDetailsForUser(StoredRoom room, StoredUser user) {
    return RoomDetails(
      summary: _roomSummaryForUser(room, user),
      hostPlayerId: room.hostUserId,
      roomPassword: room.password,
      packageFileName: room.packageFileName,
      gameState: room.gameState,
      participants: room.participants
          .map(
            (StoredRoomParticipant participant) => RoomParticipant(
              id: participant.userId,
              displayName: participant.displayName,
              isHost: participant.userId == room.hostUserId,
              isConnected: participant.isConnected,
            ),
          )
          .toList(),
    );
  }

  Future<void> _broadcastRoom(StoredRoom room,
      {required String eventType}) async {
    final Map<String, WebSocketChannel>? roomSockets = _roomSockets[room.id];
    if (roomSockets == null || roomSockets.isEmpty) {
      return;
    }

    final List<MapEntry<String, WebSocketChannel>> entries =
        roomSockets.entries.toList();
    for (final MapEntry<String, WebSocketChannel> entry in entries) {
      final StoredUser? user = _store.findUserById(entry.key);
      if (user == null) {
        continue;
      }
      final RoomRealtimeMessage payload = RoomRealtimeMessage(
        type: eventType,
        room: _roomDetailsForUser(room, user),
        gameState: room.gameState,
      );
      try {
        entry.value.sink.add(jsonEncode(payload.toJson()));
      } catch (_) {
        roomSockets.remove(entry.key);
      }
    }
  }

  Future<void> _broadcastAndCloseRoom(StoredRoom room) async {
    final Map<String, WebSocketChannel>? roomSockets = _roomSockets[room.id];
    if (roomSockets == null || roomSockets.isEmpty) {
      return;
    }

    final List<MapEntry<String, WebSocketChannel>> entries =
        roomSockets.entries.toList();
    for (final MapEntry<String, WebSocketChannel> entry in entries) {
      final StoredUser? user = _store.findUserById(entry.key);
      if (user == null) {
        continue;
      }
      final RoomRealtimeMessage payload = RoomRealtimeMessage(
        type: 'room_closed',
        room: _roomDetailsForUser(room, user),
        gameState: room.gameState,
      );
      try {
        entry.value.sink.add(jsonEncode(payload.toJson()));
        await entry.value.sink.close();
      } catch (_) {
        // Ignore socket shutdown errors while closing the room.
      }
    }
    _roomSockets.remove(room.id);
  }

  Future<void> _deleteRoom(
    StoredRoom room, {
    bool notifyClients = false,
  }) async {
    if (notifyClients) {
      await _broadcastAndCloseRoom(room);
    } else {
      final Map<String, WebSocketChannel>? roomSockets = _roomSockets.remove(
        room.id,
      );
      if (roomSockets != null) {
        for (final WebSocketChannel socket in roomSockets.values) {
          try {
            await socket.sink.close();
          } catch (_) {
            // Ignore socket shutdown errors during cleanup.
          }
        }
      }
    }
    _store.rooms.removeWhere((StoredRoom candidate) => candidate.id == room.id);
  }

  int _nowEpochMs() => DateTime.now().millisecondsSinceEpoch;

  StoredRoomParticipant? _findParticipant(StoredRoom room, String userId) {
    return room.participants.cast<StoredRoomParticipant?>().firstWhere(
          (StoredRoomParticipant? participant) =>
              participant != null && participant.userId == userId,
          orElse: () => null,
        );
  }

  StoredRoomParticipant? _hostParticipant(StoredRoom room) {
    return _findParticipant(room, room.hostUserId);
  }

  bool _isRoomHostAvailable(StoredRoom room) {
    final StoredRoomParticipant? hostParticipant = _hostParticipant(room);
    return hostParticipant != null && hostParticipant.isConnected;
  }

  bool _isHostSocketConnected(StoredRoom room) {
    return _roomSockets[room.id]?.containsKey(room.hostUserId) ?? false;
  }

  Future<void> _handleSocketClosed({
    required String roomId,
    required String userId,
    required Map<String, WebSocketChannel> sockets,
  }) async {
    final StoredRoom? latestRoom = _store.findRoomById(roomId);
    final StoredRoomParticipant? latestParticipant =
        latestRoom == null ? null : _findParticipant(latestRoom, userId);
    if (latestRoom == null || latestParticipant == null) {
      return;
    }

    latestParticipant.isConnected = false;
    if (userId == latestRoom.hostUserId) {
      latestRoom.hostDisconnectedAtEpochMs = _nowEpochMs();
    }

    sockets.remove(userId);
    if (sockets.isEmpty) {
      _roomSockets.remove(roomId);
    }

    await _store.save();
    await _broadcastRoom(latestRoom, eventType: 'room_state');
  }

  Future<void> _cleanupRoomsWithoutHost() async {
    bool changed = false;
    final int nowEpochMs = _nowEpochMs();
    final List<StoredRoom> rooms = List<StoredRoom>.from(_store.rooms);

    for (final StoredRoom room in rooms) {
      final StoredRoomParticipant? hostParticipant = _hostParticipant(room);
      if (hostParticipant == null) {
        await _deleteRoom(room, notifyClients: true);
        changed = true;
        continue;
      }

      if (_isHostSocketConnected(room)) {
        if (!hostParticipant.isConnected) {
          hostParticipant.isConnected = true;
          changed = true;
        }
        if (room.hostDisconnectedAtEpochMs != null) {
          room.hostDisconnectedAtEpochMs = null;
          changed = true;
        }
        continue;
      }

      if (hostParticipant.isConnected) {
        hostParticipant.isConnected = false;
        changed = true;
      }

      final int disconnectedAtEpochMs =
          room.hostDisconnectedAtEpochMs ?? nowEpochMs;
      if (room.hostDisconnectedAtEpochMs == null) {
        room.hostDisconnectedAtEpochMs = disconnectedAtEpochMs;
        changed = true;
      }

      final bool graceExpired = nowEpochMs - disconnectedAtEpochMs >=
          _hostlessRoomGracePeriod.inMilliseconds;
      if (!graceExpired) {
        continue;
      }

      await _deleteRoom(room, notifyClients: true);
      changed = true;
    }

    if (changed) {
      await _store.save();
    }
  }

  Future<void> _tickServer() async {
    await _cleanupRoomsWithoutHost();
    await _tickMatches();
  }

  Future<void> _tickMatches() async {
    bool changed = false;
    final List<StoredRoom> rooms = List<StoredRoom>.from(_store.rooms);
    for (final StoredRoom room in rooms) {
      if (room.status != RoomLifecycleStatus.inGame || room.gameState == null) {
        continue;
      }
      final GameState previous = room.gameState!;
      final GameState next = GameStateMachine.tick(previous);
      if (next == previous) {
        continue;
      }
      _setRoomGameState(room, next);
      changed = true;
      await _broadcastRoom(room, eventType: 'game_state');
    }
    if (changed) {
      await _store.save();
    }
  }

  Future<GameState> _initialMatchForRoom(StoredRoom room) async {
    final List<Player> players = room.participants
        .where(
          (StoredRoomParticipant participant) =>
              participant.userId != room.hostUserId,
        )
        .map(
          (StoredRoomParticipant participant) => Player(
            id: participant.userId,
            name: participant.displayName,
            score: 0,
          ),
        )
        .toList(growable: false);
    final List<Question> boardQuestions = await _store.loadQuestionsForRoom(
      room.packageFileName,
      rounds: room.rounds,
    );
    return GameStateMachine.initialMatch(
      players,
      boardQuestions: boardQuestions,
    );
  }

  void _requireGameAvailable(StoredRoom room) {
    if (room.status != RoomLifecycleStatus.inGame || room.gameState == null) {
      throw const ApiError(409, 'Match is not active');
    }
  }

  void _requireHost(StoredRoom room, StoredUser user) {
    if (room.hostUserId != user.id) {
      throw const ApiError(403, 'Only host can perform this action');
    }
  }

  void _requirePlayerCanChoose(StoredRoom room, StoredUser user) {
    final GameState state = room.gameState!;
    if (room.hostUserId == user.id) {
      return;
    }
    if (state.currentChooserId != user.id) {
      throw const ApiError(403, 'Only the current chooser can select a clue');
    }
  }

  void _requirePlayerInMatch(StoredRoom room, StoredUser user) {
    final bool isPlayer = room.gameState?.players.any(
          (Player player) => player.id == user.id,
        ) ??
        false;
    if (!isPlayer) {
      throw const ApiError(403, 'Only players can perform this action');
    }
  }

  void _syncRoomStatusFromGame(StoredRoom room) {
    final GameState? gameState = room.gameState;
    if (gameState == null) {
      return;
    }
    room.status = gameState.isMatchEnded
        ? RoomLifecycleStatus.finished
        : RoomLifecycleStatus.inGame;
  }

  int _questionsPlayed(GameState state) {
    return state.boardQuestions
        .where((Question question) => question.used)
        .length;
  }

  int _winsForScope(StoredUser user, LeaderboardScope scope) {
    switch (scope) {
      case LeaderboardScope.global:
        return user.wins;
      case LeaderboardScope.monthly:
        final int cutoffEpochMs = DateTime.now()
            .subtract(const Duration(days: 30))
            .millisecondsSinceEpoch;
        return user.recentMatches
            .where((StoredRecentMatch result) => result.won)
            .where(
              (StoredRecentMatch result) =>
                  result.playedAtEpochMs >= cutoffEpochMs,
            )
            .length;
      case LeaderboardScope.daily:
        final int cutoffEpochMs = DateTime.now()
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch;
        return user.recentMatches
            .where((StoredRecentMatch result) => result.won)
            .where(
              (StoredRecentMatch result) =>
                  result.playedAtEpochMs >= cutoffEpochMs,
            )
            .length;
    }
  }

  bool _isPublicLeaderboardUser(StoredUser user) {
    final String email = user.email.trim().toLowerCase();
    return !email.endsWith('@example.com');
  }

  void _addRecentMatch(
    StoredUser user,
    StoredRoom room,
    Player? player, {
    required bool won,
    required int playedAtEpochMs,
    bool wasHost = false,
    int clutchAnswers = 0,
  }) {
    user.recentMatches.insert(
      0,
      StoredRecentMatch(
        roomName: room.name,
        score: player?.score,
        won: won,
        mode: room.mode,
        playedAtEpochMs: playedAtEpochMs,
        wasHost: wasHost,
        clutchAnswers: clutchAnswers,
      ),
    );
  }

  void _updateWinRate(StoredUser user) {
    final int decidedMatches = user.wins + user.losses;
    user.winRate = decidedMatches == 0 ? 0 : user.wins / decidedMatches;
  }

  void _grantAchievementRewardIfNeeded(
    StoredUser user, {
    required String achievementId,
    required int rewardXp,
  }) {
    if (user.unlockedAchievementIds.contains(achievementId)) {
      return;
    }
    user.unlockedAchievementIds.add(achievementId);
    user.totalXp += rewardXp;
  }

  void _recordAcceptedAnswerProgress(StoredRoom room, GameState previousState) {
    final String? answeringPlayerId = previousState.pendingAnswerPlayerId;
    if (answeringPlayerId == null) {
      return;
    }

    room.matchProgress.correctAnswersByPlayerId.update(
      answeringPlayerId,
      (int value) => value + 1,
      ifAbsent: () => 1,
    );

    final List<String> otherPlayerIds = previousState.players
        .where((Player player) => player.id != answeringPlayerId)
        .map((Player player) => player.id)
        .toList(growable: false);
    final bool everyoneElseWasWrong = otherPlayerIds.isNotEmpty &&
        otherPlayerIds.every(previousState.wrongAnswerPlayerIds.contains);
    if (!everyoneElseWasWrong) {
      return;
    }

    room.matchProgress.clutchAnswersByPlayerId.update(
      answeringPlayerId,
      (int value) => value + 1,
      ifAbsent: () => 1,
    );
  }

  void _finalizeMatchProfileIfNeeded(
    StoredRoom room, {
    required GameState? previousState,
    required GameState nextState,
  }) {
    if (!shouldApplyMatchProfileUpdates(
      previousState: previousState,
      nextState: nextState,
      matchProgress: room.matchProgress,
    )) {
      return;
    }

    final int playedQuestions = _questionsPlayed(nextState);
    final int nowEpochMs = _nowEpochMs();

    for (final Player player in nextState.players) {
      final StoredUser? user = _store.findUserById(player.id);
      if (user == null) {
        continue;
      }

      final bool won = nextState.winnerId == player.id;
      final int correctAnswers =
          room.matchProgress.correctAnswersByPlayerId[player.id] ?? 0;
      final int clutchAnswers =
          room.matchProgress.clutchAnswersByPlayerId[player.id] ?? 0;

      user.gamesPlayed += 1;
      user.totalXp += playedQuestions * 20;
      user.totalXp += correctAnswers * 20;
      user.clutchCorrectAnswers += clutchAnswers;

      if (won) {
        user.wins += 1;
        _grantAchievementRewardIfNeeded(
          user,
          achievementId: _firstWinAchievementId,
          rewardXp: 500,
        );
      } else {
        user.losses += 1;
      }

      if (clutchAnswers > 0) {
        _grantAchievementRewardIfNeeded(
          user,
          achievementId: _clutchAnswerAchievementId,
          rewardXp: 750,
        );
      }

      user.bestScore = max(user.bestScore, player.score);
      _addRecentMatch(
        user,
        room,
        player,
        won: won,
        playedAtEpochMs: nowEpochMs,
        clutchAnswers: clutchAnswers,
      );
      _updateWinRate(user);
    }

    final StoredUser? host = _store.findUserById(room.hostUserId);
    if (host != null) {
      host.gamesPlayed += 1;
      host.totalXp += playedQuestions * 30;
      _addRecentMatch(
        host,
        room,
        null,
        won: false,
        playedAtEpochMs: nowEpochMs,
        wasHost: true,
      );
      _updateWinRate(host);
    }

    room.matchProgress.profileApplied = true;
  }

  void _setRoomGameState(StoredRoom room, GameState nextState) {
    final GameState? previousState = room.gameState;
    room.gameState = nextState;
    _syncRoomStatusFromGame(room);
    _finalizeMatchProfileIfNeeded(
      room,
      previousState: previousState,
      nextState: nextState,
    );
  }

  GameState _removePlayerFromGameState(GameState state, String playerId) {
    final List<Player> remainingPlayers = state.players
        .where((Player player) => player.id != playerId)
        .toList(growable: false);
    final String? nextChooserId = remainingPlayers
            .any((Player player) => player.id == state.currentChooserId)
        ? state.currentChooserId
        : (remainingPlayers.isEmpty ? null : remainingPlayers.first.id);
    final String nextQuestionOwnerId = remainingPlayers.any(
      (Player player) => player.id == state.questionOwnerId,
    )
        ? state.questionOwnerId
        : (nextChooserId ?? '');
    final GameState next = state.copyWith(
      players: remainingPlayers,
      currentChooserId: nextChooserId ?? '',
      questionOwnerId: nextQuestionOwnerId,
      pendingAnswerPlayerId: state.pendingAnswerPlayerId == playerId
          ? null
          : state.pendingAnswerPlayerId,
      passedPlayerIds: state.passedPlayerIds
          .where((String id) => id != playerId)
          .toList(growable: false),
      wrongAnswerPlayerIds: state.wrongAnswerPlayerIds
          .where((String id) => id != playerId)
          .toList(growable: false),
      lastCorrectAnswerPlayerId: state.lastCorrectAnswerPlayerId == playerId
          ? null
          : state.lastCorrectAnswerPlayerId,
      winnerId: state.winnerId == playerId ? null : state.winnerId,
    );
    if (remainingPlayers.length <= 1) {
      return next.copyWith(
        phase: GamePhase.finished,
        isMatchEnded: true,
        winnerId: remainingPlayers.isEmpty ? null : remainingPlayers.first.id,
        clearCurrentQuestion: true,
        phaseSecondsLeft: 0,
        phaseSecondsTotal: 0,
        pendingAnswerSecondsLeft: 0,
        pendingAnswerSecondsTotal: 0,
        pendingAnswerPlayerId: null,
        lastEvent: remainingPlayers.isEmpty
            ? 'Match ended because all players left.'
            : '${remainingPlayers.first.name} wins because other players left.',
      );
    }
    return next;
  }

  Future<Response> _guarded(
    FutureOr<Response> Function() action,
  ) async {
    try {
      return await action();
    } on ApiError catch (error) {
      return _json(<String, dynamic>{'error': error.message},
          status: error.code);
    } catch (error, stackTrace) {
      stderr.writeln(error);
      stderr.writeln(stackTrace);
      return _json(
        <String, dynamic>{'error': 'Internal server error'},
        status: 500,
      );
    }
  }

  Future<Response> _handleHealth(Request request) async {
    return _json(<String, dynamic>{'ok': true});
  }

  Future<Response> _handleRegister(Request request) {
    return _guarded(() async {
      final Map<String, dynamic> json = await _readJson(request);
      final String displayName = (json['displayName'] as String? ?? '').trim();
      final String password = json['password'] as String? ?? '';
      if (displayName.length < 3) {
        throw const ApiError(400, 'Nickname must be at least 3 characters');
      }
      if (password.length < 6) {
        throw const ApiError(400, 'Password must be at least 6 characters');
      }
      if (_store.findUserByDisplayName(displayName) != null) {
        throw const ApiError(409, 'Nickname is already taken');
      }

      final String userId = _store.nextId('user');

      final StoredUser user = StoredUser(
        id: userId,
        sessionToken: _store.nextSecret('session'),
        email: _generatedEmailForUserId(userId),
        displayName: displayName,
        passwordHash: _hashPassword(password),
        gamesPlayed: 0,
        winRate: 0,
        bestScore: 0,
        wins: 0,
        losses: 0,
        totalXp: 0,
        clutchCorrectAnswers: 0,
        unlockedAchievementIds: <String>[],
        recentMatches: <StoredRecentMatch>[],
        settings: UserSettingsDto.defaults,
      );
      _store.users.add(user);
      await _store.save();

      final BootstrapPayload payload = BootstrapPayload(
        session: user.toSession(),
        profile: user.toProfile(),
        settings: user.settings,
      );
      return _json(payload.toJson(), status: 201);
    });
  }

  Future<Response> _handleLogin(Request request) {
    return _guarded(() async {
      final Map<String, dynamic> json = await _readJson(request);
      final String credential = (json['credential'] as String? ?? '').trim();
      final String password = json['password'] as String? ?? '';
      if (credential.isEmpty || password.isEmpty) {
        throw const ApiError(400, 'Nickname and password are required');
      }

      final StoredUser? user = credential.contains('@')
          ? _store.findUserByEmail(_normalizeEmail(credential))
          : _store.findUserByDisplayName(credential);
      if (user == null || user.passwordHash != _hashPassword(password)) {
        throw const ApiError(401, 'Invalid credentials');
      }

      user.sessionToken = _store.nextSecret('session');
      await _store.save();

      final BootstrapPayload payload = BootstrapPayload(
        session: user.toSession(),
        profile: user.toProfile(),
        settings: user.settings,
      );
      return _json(payload.toJson());
    });
  }

  Future<Response> _handleMe(Request request) {
    return _guarded(() async {
      final StoredUser user = _requireUser(request);
      final BootstrapPayload payload = BootstrapPayload(
        session: user.toSession(),
        profile: user.toProfile(),
        settings: user.settings,
      );
      return _json(payload.toJson());
    });
  }

  Future<Response> _handleSaveSettings(Request request) {
    return _guarded(() async {
      final StoredUser user = _requireUser(request);
      final Map<String, dynamic> json = await _readJson(request);
      user.settings = UserSettingsDto.fromJson(json);
      await _store.save();
      return _json(<String, dynamic>{'ok': true});
    });
  }

  Future<Response> _handleLeaderboard(Request request) {
    return _guarded(() async {
      _requireUser(request);
      final String scopeName =
          (request.url.queryParameters['scope'] ?? '').trim().toLowerCase();
      final LeaderboardScope scope = LeaderboardScope.values.firstWhere(
        (LeaderboardScope value) => value.name == scopeName,
        orElse: () => LeaderboardScope.global,
      );
      final List<StoredUser> sorted =
          _store.users.where(_isPublicLeaderboardUser).toList(growable: false)
            ..sort((StoredUser a, StoredUser b) {
              final int byWins =
                  _winsForScope(b, scope).compareTo(_winsForScope(a, scope));
              if (byWins != 0) {
                return byWins;
              }
              final int byXp = b.totalXp.compareTo(a.totalXp);
              if (byXp != 0) {
                return byXp;
              }
              return a.displayName.compareTo(b.displayName);
            });

      final List<LeaderboardEntry> entries = <LeaderboardEntry>[];
      for (int index = 0; index < sorted.length; index++) {
        final StoredUser user = sorted[index];
        entries.add(
          LeaderboardEntry(
            rank: index + 1,
            playerName: user.displayName,
            score: _winsForScope(user, scope),
          ),
        );
      }
      return _json(
          entries.map((LeaderboardEntry entry) => entry.toJson()).toList());
    });
  }

  Future<Response> _handleRooms(Request request) {
    return _guarded(() async {
      final StoredUser user = _requireUser(request);
      final List<RoomSummary> rooms = _store.rooms
          .where((StoredRoom room) =>
              room.status == RoomLifecycleStatus.waiting &&
              _isRoomHostAvailable(room))
          .map((StoredRoom room) => _roomSummaryForUser(room, user))
          .toList()
        ..sort((RoomSummary a, RoomSummary b) => a.name.compareTo(b.name));
      return _json(rooms.map((RoomSummary room) => room.toJson()).toList());
    });
  }

  Future<Response> _handleCreateRoom(Request request) {
    return _guarded(() async {
      final StoredUser user = _requireUser(request);
      final Map<String, dynamic> json = await _readJson(request);
      final CreateRoomRequest createRoomRequest = CreateRoomRequest(
        name: (json['name'] as String? ?? '').trim(),
        password: (json['password'] as String? ?? '').trim(),
        mode: (json['mode'] as String? ?? 'multiplayer').trim(),
        topic: (json['topic'] as String? ?? 'General').trim(),
        rounds: (json['rounds'] as num?)?.toInt() ?? 3,
        finalWagerEnabled: json['finalWagerEnabled'] as bool? ?? false,
        maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 4,
        packageFileName: (json['packageFileName'] as String? ?? '').trim(),
      );

      final StoredRoom room = StoredRoom(
        id: _store.nextId('room'),
        code: _store.nextRoomCode(),
        name: createRoomRequest.name.isEmpty
            ? 'Guess Together Room'
            : createRoomRequest.name,
        topic: createRoomRequest.topic.isEmpty
            ? 'General Trivia'
            : createRoomRequest.topic,
        rounds: createRoomRequest.rounds,
        mode: createRoomRequest.mode,
        maxPlayers: createRoomRequest.maxPlayers.clamp(2, 8),
        password: createRoomRequest.password,
        hostUserId: user.id,
        packageFileName: createRoomRequest.packageFileName.isEmpty
            ? _defaultPackageFileName
            : createRoomRequest.packageFileName,
        status: RoomLifecycleStatus.waiting,
        matchProgress: StoredMatchProgress(),
        participants: <StoredRoomParticipant>[
          StoredRoomParticipant(
            userId: user.id,
            displayName: user.displayName,
            isConnected: true,
          ),
        ],
      );

      _store.rooms.add(room);
      await _store.save();
      return _json(_roomSummaryForUser(room, user).toJson(), status: 201);
    });
  }

  Future<Response> _handleJoinRoom(Request request) {
    return _guarded(() async {
      final StoredUser user = _requireUser(request);
      final Map<String, dynamic> json = await _readJson(request);
      final String code = (json['code'] as String? ?? '').trim();
      final String password = (json['password'] as String? ?? '').trim();
      final StoredRoom? room = _store.rooms.cast<StoredRoom?>().firstWhere(
            (StoredRoom? candidate) =>
                candidate != null &&
                candidate.code == code &&
                candidate.status == RoomLifecycleStatus.waiting,
            orElse: () => null,
          );
      if (room == null) {
        throw const ApiError(404, 'Room not found');
      }
      if (!_isRoomHostAvailable(room)) {
        throw const ApiError(409, 'Room is no longer active');
      }
      if (room.password.isNotEmpty && room.password != password) {
        throw const ApiError(403, 'Wrong password');
      }
      final bool alreadyMember = room.participants.any(
        (StoredRoomParticipant participant) => participant.userId == user.id,
      );
      if (!alreadyMember && room.playerCount >= room.maxPlayers) {
        throw const ApiError(409, 'Room is full');
      }
      if (!alreadyMember) {
        room.participants.add(
          StoredRoomParticipant(
            userId: user.id,
            displayName: user.displayName,
            isConnected: false,
          ),
        );
        await _store.save();
        await _broadcastRoom(room, eventType: 'room_state');
      }
      return _json(_roomSummaryForUser(room, user).toJson());
    });
  }

  Future<Response> _handleRoomDetails(Request request, String roomId) {
    return _guarded(() async {
      final StoredUser user = _requireUser(request);
      final StoredRoom room = _requireRoom(roomId);
      _requireRoomMember(room, user);
      return _json(_roomDetailsForUser(room, user).toJson());
    });
  }

  Future<Response> _handleLeaveRoom(Request request, String roomId) {
    return _guarded(() async {
      final StoredUser user = _requireUser(request);
      final StoredRoom room = _requireRoom(roomId);
      _requireRoomMember(room, user);

      final bool wasHost = room.hostUserId == user.id;

      room.participants.removeWhere(
        (StoredRoomParticipant participant) => participant.userId == user.id,
      );
      _roomSockets[room.id]?.remove(user.id);

      if (wasHost || room.participants.isEmpty) {
        await _deleteRoom(room, notifyClients: true);
        await _store.save();
        return _json(<String, dynamic>{'ok': true});
      }

      if (room.gameState != null &&
          room.status != RoomLifecycleStatus.finished) {
        final GameState nextState =
            _removePlayerFromGameState(room.gameState!, user.id);
        if (!(room.gameState?.isMatchEnded ?? false) && nextState.isMatchEnded) {
          room.matchProgress.endedByAbandonment = true;
        }
        _setRoomGameState(room, nextState);
      }

      await _store.save();
      await _broadcastRoom(room, eventType: 'room_state');
      return _json(<String, dynamic>{'ok': true});
    });
  }

  Future<Response> _handleStartRoom(Request request, String roomId) {
    return _guarded(() async {
      final StoredUser user = _requireUser(request);
      final StoredRoom room = _requireRoom(roomId);
      _requireRoomMember(room, user);
      _requireHost(room, user);
      if (room.playerCount < 2) {
        throw const ApiError(409, 'At least 2 players are required to start');
      }
      room.status = RoomLifecycleStatus.inGame;
      room.gameState = await _initialMatchForRoom(room);
      room.matchProgress = StoredMatchProgress();
      _syncRoomStatusFromGame(room);
      await _store.save();
      await _broadcastRoom(room, eventType: 'room_started');
      return _json(<String, dynamic>{'ok': true});
    });
  }

  Future<Response> _handleChooseQuestion(Request request, String roomId) {
    return _guarded(() async {
      final StoredUser user = _requireUser(request);
      final StoredRoom room = _requireRoom(roomId);
      _requireRoomMember(room, user);
      _requireGameAvailable(room);
      _requirePlayerCanChoose(room, user);
      final Map<String, dynamic> json = await _readJson(request);
      final String questionId = (json['questionId'] as String? ?? '').trim();
      if (questionId.isEmpty) {
        throw const ApiError(400, 'Question id is required');
      }
      _setRoomGameState(
        room,
        GameStateMachine.chooseQuestion(
          room.gameState!,
          questionId: questionId,
          hostOverride: room.hostUserId == user.id,
        ),
      );
      await _store.save();
      await _broadcastRoom(room, eventType: 'game_state');
      return _json(<String, dynamic>{'ok': true});
    });
  }

  Future<Response> _handleRequestAnswer(Request request, String roomId) {
    return _guarded(() async {
      final StoredUser user = _requireUser(request);
      final StoredRoom room = _requireRoom(roomId);
      _requireRoomMember(room, user);
      _requireGameAvailable(room);
      _requirePlayerInMatch(room, user);
      _setRoomGameState(
        room,
        GameStateMachine.requestAnswer(room.gameState!, user.id),
      );
      await _store.save();
      await _broadcastRoom(room, eventType: 'game_state');
      return _json(<String, dynamic>{'ok': true});
    });
  }

  Future<Response> _handlePassQuestion(Request request, String roomId) {
    return _guarded(() async {
      final StoredUser user = _requireUser(request);
      final StoredRoom room = _requireRoom(roomId);
      _requireRoomMember(room, user);
      _requireGameAvailable(room);
      _requirePlayerInMatch(room, user);
      _setRoomGameState(
        room,
        GameStateMachine.passQuestion(room.gameState!, user.id),
      );
      await _store.save();
      await _broadcastRoom(room, eventType: 'game_state');
      return _json(<String, dynamic>{'ok': true});
    });
  }

  Future<Response> _handleAcceptAnswer(Request request, String roomId) {
    return _guarded(() async {
      final StoredUser user = _requireUser(request);
      final StoredRoom room = _requireRoom(roomId);
      _requireRoomMember(room, user);
      _requireGameAvailable(room);
      _requireHost(room, user);
      _recordAcceptedAnswerProgress(room, room.gameState!);
      _setRoomGameState(
        room,
        GameStateMachine.acceptAnswer(room.gameState!),
      );
      await _store.save();
      await _broadcastRoom(room, eventType: 'game_state');
      return _json(<String, dynamic>{'ok': true});
    });
  }

  Future<Response> _handleRejectAnswer(Request request, String roomId) {
    return _guarded(() async {
      final StoredUser user = _requireUser(request);
      final StoredRoom room = _requireRoom(roomId);
      _requireRoomMember(room, user);
      _requireGameAvailable(room);
      _requireHost(room, user);
      _setRoomGameState(
        room,
        GameStateMachine.rejectAnswer(room.gameState!),
      );
      await _store.save();
      await _broadcastRoom(room, eventType: 'game_state');
      return _json(<String, dynamic>{'ok': true});
    });
  }

  Future<Response> _handleTogglePause(Request request, String roomId) {
    return _guarded(() async {
      final StoredUser user = _requireUser(request);
      final StoredRoom room = _requireRoom(roomId);
      _requireRoomMember(room, user);
      _requireGameAvailable(room);
      _requireHost(room, user);
      _setRoomGameState(
        room,
        GameStateMachine.togglePause(room.gameState!),
      );
      await _store.save();
      await _broadcastRoom(room, eventType: 'game_state');
      return _json(<String, dynamic>{'ok': true});
    });
  }

  Future<Response> _handleSkipQuestion(Request request, String roomId) {
    return _guarded(() async {
      final StoredUser user = _requireUser(request);
      final StoredRoom room = _requireRoom(roomId);
      _requireRoomMember(room, user);
      _requireGameAvailable(room);
      _requireHost(room, user);
      _setRoomGameState(
        room,
        GameStateMachine.skipQuestion(room.gameState!),
      );
      await _store.save();
      await _broadcastRoom(room, eventType: 'game_state');
      return _json(<String, dynamic>{'ok': true});
    });
  }

  Future<Response> _handleSkipRound(Request request, String roomId) {
    return _guarded(() async {
      final StoredUser user = _requireUser(request);
      final StoredRoom room = _requireRoom(roomId);
      _requireRoomMember(room, user);
      _requireGameAvailable(room);
      _requireHost(room, user);
      _setRoomGameState(
        room,
        GameStateMachine.skipRound(room.gameState!),
      );
      await _store.save();
      await _broadcastRoom(room, eventType: 'game_state');
      return _json(<String, dynamic>{'ok': true});
    });
  }

  Future<Response> _handleSetPlayerScore(Request request, String roomId) {
    return _guarded(() async {
      final StoredUser user = _requireUser(request);
      final StoredRoom room = _requireRoom(roomId);
      _requireRoomMember(room, user);
      _requireGameAvailable(room);
      _requireHost(room, user);
      final Map<String, dynamic> json = await _readJson(request);
      final String playerId = (json['playerId'] as String? ?? '').trim();
      final int? score = (json['score'] as num?)?.toInt();
      if (playerId.isEmpty || score == null) {
        throw const ApiError(400, 'Player id and score are required');
      }
      final bool playerExists = room.gameState!.players.any(
        (Player player) => player.id == playerId,
      );
      if (!playerExists) {
        throw const ApiError(404, 'Player not found');
      }
      _setRoomGameState(
        room,
        GameStateMachine.setPlayerScore(
          room.gameState!,
          playerId: playerId,
          score: score,
        ),
      );
      await _store.save();
      await _broadcastRoom(room, eventType: 'game_state');
      return _json(<String, dynamic>{'ok': true});
    });
  }

  FutureOr<Response> _handleRoomSocket(Request request, String roomId) {
    return webSocketHandler(
      (WebSocketChannel webSocket, String? protocol) async {
        final String token = request.url.queryParameters['token'] ?? '';
        final StoredUser? user = _store.findUserByToken(token);
        final StoredRoom? room = _store.findRoomById(roomId);
        if (user == null || room == null) {
          await webSocket.sink.close();
          return;
        }
        final StoredRoomParticipant? participant =
            room.participants.cast<StoredRoomParticipant?>().firstWhere(
                  (StoredRoomParticipant? value) =>
                      value != null && value.userId == user.id,
                  orElse: () => null,
                );
        if (participant == null) {
          await webSocket.sink.close();
          return;
        }

        participant.isConnected = true;
        if (user.id == room.hostUserId) {
          room.hostDisconnectedAtEpochMs = null;
        }
        final Map<String, WebSocketChannel> sockets = _roomSockets.putIfAbsent(
            room.id, () => <String, WebSocketChannel>{});
        sockets[user.id] = webSocket;
        await _store.save();
        await _broadcastRoom(room, eventType: 'room_state');

        unawaited(
          webSocket.stream
              .listen(
                (_) {},
                onDone: () => unawaited(
                  _handleSocketClosed(
                    roomId: room.id,
                    userId: user.id,
                    sockets: sockets,
                  ),
                ),
                onError: (_) => unawaited(
                  _handleSocketClosed(
                    roomId: room.id,
                    userId: user.id,
                    sockets: sockets,
                  ),
                ),
                cancelOnError: true,
              )
              .asFuture<void>(),
        );
      },
    )(request);
  }
}

class ApiError implements Exception {
  const ApiError(this.code, this.message);

  final int code;
  final String message;
}

class _AppStateStore {
  _AppStateStore({
    required String databaseUrl,
    required _QuestionPackageRepository packageRepository,
  }) : _database = _PostgresDatabase(
          databaseUrl,
          packageRepository: packageRepository,
        );

  final _PostgresDatabase _database;
  final Random _random = Random.secure();
  final List<StoredUser> users = <StoredUser>[];
  final List<StoredRoom> rooms = <StoredRoom>[];

  String get connectionSummary => _database.connectionSummary;

  Future<List<Question>> loadQuestionsForRoom(
    String packageFileName, {
    required int rounds,
  }) {
    return _database.loadQuestions(packageFileName, rounds: rounds);
  }

  Future<void> load() async {
    await _database.open();
    await _database.ensureSchema();
    users.clear();
    rooms.clear();
    users.addAll(await _database.loadUsers());
    rooms.addAll(await _database.loadRooms());
  }

  Future<void> save() async {
    await _database.saveSnapshot(users: users, rooms: rooms);
  }

  StoredUser? findUserByToken(String token) {
    for (final StoredUser user in users) {
      if (user.sessionToken == token) {
        return user;
      }
    }
    return null;
  }

  StoredUser? findUserById(String userId) {
    for (final StoredUser user in users) {
      if (user.id == userId) {
        return user;
      }
    }
    return null;
  }

  StoredUser? findUserByEmail(String email) {
    final String normalized = email.trim().toLowerCase();
    for (final StoredUser user in users) {
      if (user.email.trim().toLowerCase() == normalized) {
        return user;
      }
    }
    return null;
  }

  StoredUser? findUserByDisplayName(String displayName) {
    final String normalized = displayName.trim().toLowerCase();
    for (final StoredUser user in users) {
      if (user.displayName.trim().toLowerCase() == normalized) {
        return user;
      }
    }
    return null;
  }

  StoredRoom? findRoomById(String roomId) {
    for (final StoredRoom room in rooms) {
      if (room.id == roomId) {
        return room;
      }
    }
    return null;
  }

  String nextId(String prefix) {
    final int millis = DateTime.now().millisecondsSinceEpoch;
    final int tail = _random.nextInt(999999);
    return '$prefix-$millis-$tail';
  }

  String nextSecret(String prefix) {
    final StringBuffer buffer = StringBuffer(prefix);
    for (int i = 0; i < 6; i++) {
      buffer.write(_random.nextInt(16).toRadixString(16));
    }
    buffer.write(DateTime.now().microsecondsSinceEpoch.toRadixString(16));
    return buffer.toString();
  }

  String nextRoomCode() {
    for (int attempt = 0; attempt < 1000; attempt++) {
      final String code = (1000 + _random.nextInt(9000)).toString();
      final bool taken = rooms.any((StoredRoom room) => room.code == code);
      if (!taken) {
        return code;
      }
    }
    return (1000 + _random.nextInt(9000)).toString();
  }
}

class _PostgresDatabase {
  _PostgresDatabase(this.databaseUrl,
      {required _QuestionPackageRepository packageRepository})
      : _packageRepository = packageRepository;

  final String databaseUrl;
  final _QuestionPackageRepository _packageRepository;
  Connection? _connection;

  String get connectionSummary {
    final Uri uri = Uri.parse(databaseUrl);
    final String database =
        uri.pathSegments.isEmpty ? 'postgres' : uri.pathSegments.join('/');
    final String user =
        uri.userInfo.isEmpty ? '' : '${uri.userInfo.split(':').first}@';
    final int port = uri.hasPort ? uri.port : 5432;
    return '${uri.scheme}://$user${uri.host}:$port/$database';
  }

  Future<void> open() async {
    _connection ??= await Connection.openFromUrl(databaseUrl);
  }

  Future<void> ensureSchema() async {
    final Connection connection = await _requireConnection();
    if (await _needsSchemaReset(connection)) {
      await _dropManagedTables(connection);
    }
    final List<Object> statements = <Object>[
      'DROP TABLE IF EXISTS app_rooms CASCADE',
      'DROP TABLE IF EXISTS app_users CASCADE',
      'DROP TABLE IF EXISTS recent_matches CASCADE',
      'DROP TABLE IF EXISTS win_history CASCADE',
      '''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        session_token TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL,
        name TEXT NOT NULL,
        password TEXT NOT NULL,
        games_played INTEGER NOT NULL DEFAULT 0,
        win_rate DOUBLE PRECISION NOT NULL DEFAULT 0,
        wins INTEGER NOT NULL DEFAULT 0,
        losses INTEGER NOT NULL DEFAULT 0,
        total_xp INTEGER NOT NULL DEFAULT 0,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
      ''',
      '''
      CREATE UNIQUE INDEX IF NOT EXISTS users_email_lower_key
      ON users (LOWER(email))
      ''',
      '''
      CREATE UNIQUE INDEX IF NOT EXISTS users_name_lower_key
      ON users (LOWER(name))
      ''',
      '''
      CREATE TABLE IF NOT EXISTS settings (
        user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
        theme_mode TEXT NOT NULL DEFAULT '',
        language_code TEXT NOT NULL DEFAULT ''
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS achivements (
        id TEXT PRIMARY KEY,
        title_key TEXT NOT NULL,
        requirement_key TEXT NOT NULL,
        reward_xp INTEGER NOT NULL DEFAULT 0
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS link_users_achivements (
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        achivement_id TEXT NOT NULL REFERENCES achivements(id)
            ON DELETE CASCADE,
        PRIMARY KEY (user_id, achivement_id)
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS results (
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        result_order INTEGER NOT NULL,
        room_name TEXT NOT NULL,
        score INTEGER,
        won BOOLEAN NOT NULL,
        mode TEXT NOT NULL,
        played_at_epoch_ms BIGINT NOT NULL,
        was_host BOOLEAN NOT NULL DEFAULT FALSE,
        clutch_answers INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (user_id, result_order)
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS rooms (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        topic TEXT NOT NULL,
        rounds INTEGER NOT NULL,
        mode TEXT NOT NULL,
        max_players INTEGER NOT NULL,
        password TEXT NOT NULL,
        host_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        package_file_name TEXT NOT NULL,
        status TEXT NOT NULL,
        phase TEXT,
        is_paused BOOLEAN NOT NULL DEFAULT FALSE,
        round INTEGER,
        current_chooser_id TEXT,
        question_owner_id TEXT,
        phase_seconds_left INTEGER NOT NULL DEFAULT 0,
        phase_seconds_total INTEGER NOT NULL DEFAULT 0,
        pending_answer_seconds_left INTEGER NOT NULL DEFAULT 0,
        pending_answer_seconds_total INTEGER NOT NULL DEFAULT 0,
        pending_answer_player_id TEXT,
        last_correct_answer_player_id TEXT,
        is_match_ended BOOLEAN NOT NULL DEFAULT FALSE,
        winner_id TEXT,
        last_event TEXT NOT NULL DEFAULT '',
        current_question_id TEXT,
        used_question_ids TEXT NOT NULL DEFAULT '',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
      ''',
      '''
      CREATE INDEX IF NOT EXISTS rooms_status_idx
      ON rooms (status)
      ''',
      '''
      CREATE INDEX IF NOT EXISTS rooms_host_user_id_idx
      ON rooms (host_user_id)
      ''',
      '''
      CREATE TABLE IF NOT EXISTS link_users_rooms (
        room_id TEXT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        display_name TEXT NOT NULL,
        is_connected BOOLEAN NOT NULL DEFAULT FALSE,
        participant_order INTEGER NOT NULL,
        score INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (room_id, user_id)
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS room_match_progress (
        room_id TEXT PRIMARY KEY REFERENCES rooms(id) ON DELETE CASCADE,
        profile_applied BOOLEAN NOT NULL DEFAULT FALSE,
        ended_by_abandonment BOOLEAN NOT NULL DEFAULT FALSE
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS room_match_player_stats (
        room_id TEXT NOT NULL REFERENCES room_match_progress(room_id)
            ON DELETE CASCADE,
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        correct_answers INTEGER NOT NULL DEFAULT 0,
        clutch_answers INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (room_id, user_id)
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS game_answer_flags (
        room_id TEXT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        flag_type TEXT NOT NULL CHECK (flag_type IN ('passed', 'wrong')),
        flag_order INTEGER NOT NULL,
        PRIMARY KEY (room_id, user_id, flag_type)
      )
      ''',
      Sql.named(
        '''
        INSERT INTO achivements (
          id,
          title_key,
          requirement_key,
          reward_xp
        ) VALUES
          (
            @firstWinId,
            'achievementFirstWinTitle',
            'achievementFirstWinRequirement',
            500
          ),
          (
            @clutchAnswerId,
            'achievementClutchAnswerTitle',
            'achievementClutchAnswerRequirement',
            750
          )
        ON CONFLICT (id) DO UPDATE SET
          title_key = EXCLUDED.title_key,
          requirement_key = EXCLUDED.requirement_key,
          reward_xp = EXCLUDED.reward_xp
        ''',
      ),
    ];

    for (final Object statement in statements) {
      if (statement is String) {
        await connection.execute(statement);
        continue;
      }
      await connection.execute(
        statement as Sql,
        parameters: <String, Object?>{
          'firstWinId': _firstWinAchievementId,
          'clutchAnswerId': _clutchAnswerAchievementId,
        },
      );
    }
    await connection.execute(
      '''
      ALTER TABLE room_match_progress
      ADD COLUMN IF NOT EXISTS ended_by_abandonment BOOLEAN NOT NULL DEFAULT FALSE
      ''',
    );
  }

  Future<bool> _needsSchemaReset(Connection connection) async {
    final Result result = await connection.execute(
      '''
      SELECT
        EXISTS (
          SELECT 1
          FROM information_schema.columns
          WHERE table_schema = 'public'
            AND table_name = 'users'
            AND column_name IN ('display_name', 'password_hash', 'best_score')
        ) OR EXISTS (
          SELECT 1
          FROM information_schema.tables
          WHERE table_schema = 'public'
            AND table_name IN (
              'recent_matches',
              'win_history',
              'user_settings',
              'user_achievements',
              'room_participants',
              'game_players',
              'game_questions'
            )
        ) OR EXISTS (
          SELECT 1
          FROM information_schema.tables
          WHERE table_schema = 'public'
            AND table_name = 'game_states'
        ) OR EXISTS (
          SELECT 1
          FROM information_schema.columns
          WHERE table_schema = 'public'
            AND table_name = 'rooms'
            AND column_name = 'host_disconnected_at_epoch_ms'
        ) OR NOT EXISTS (
          SELECT 1
          FROM information_schema.columns
          WHERE table_schema = 'public'
            AND table_name = 'rooms'
            AND column_name = 'phase'
        ) OR NOT EXISTS (
          SELECT 1
          FROM information_schema.tables
          WHERE table_schema = 'public'
            AND table_name = 'settings'
        ) OR NOT EXISTS (
          SELECT 1
          FROM information_schema.tables
          WHERE table_schema = 'public'
            AND table_name = 'link_users_achivements'
        ) OR NOT EXISTS (
          SELECT 1
          FROM information_schema.tables
          WHERE table_schema = 'public'
            AND table_name = 'achivements'
        ) OR EXISTS (
          SELECT 1
          FROM information_schema.tables
          WHERE table_schema = 'public'
            AND table_name = 'game_questions'
        )
      ''',
    );
    return result.first.first as bool? ?? false;
  }

  Future<void> _dropManagedTables(Connection connection) async {
    final List<String> dropStatements = <String>[
      'DROP TABLE IF EXISTS game_answer_flags CASCADE',
      'DROP TABLE IF EXISTS game_questions CASCADE',
      'DROP TABLE IF EXISTS game_players CASCADE',
      'DROP TABLE IF EXISTS game_states CASCADE',
      'DROP TABLE IF EXISTS room_match_player_stats CASCADE',
      'DROP TABLE IF EXISTS room_match_progress CASCADE',
      'DROP TABLE IF EXISTS room_participants CASCADE',
      'DROP TABLE IF EXISTS link_users_rooms CASCADE',
      'DROP TABLE IF EXISTS rooms CASCADE',
      'DROP TABLE IF EXISTS results CASCADE',
      'DROP TABLE IF EXISTS recent_matches CASCADE',
      'DROP TABLE IF EXISTS win_history CASCADE',
      'DROP TABLE IF EXISTS user_achievements CASCADE',
      'DROP TABLE IF EXISTS user_settings CASCADE',
      'DROP TABLE IF EXISTS link_users_achivements CASCADE',
      'DROP TABLE IF EXISTS achivements CASCADE',
      'DROP TABLE IF EXISTS settings CASCADE',
      'DROP TABLE IF EXISTS users CASCADE',
      'DROP TABLE IF EXISTS app_rooms CASCADE',
      'DROP TABLE IF EXISTS app_users CASCADE',
    ];
    for (final String statement in dropStatements) {
      await connection.execute(statement);
    }
  }

  Future<List<Question>> loadQuestions(
    String packageFileName, {
    required int rounds,
  }) {
    return _packageRepository.loadQuestions(packageFileName, rounds: rounds);
  }

  Future<List<StoredUser>> loadUsers() async {
    final Connection connection = await _requireConnection();
    final Result result = await connection.execute(
      '''
      SELECT
        id,
        session_token,
        email,
        name,
        password,
        games_played,
        win_rate,
        wins,
        losses,
        total_xp
      FROM users
      ORDER BY LOWER(name), id
      ''',
    );
    final List<StoredUser> users = result.map((ResultRow row) {
      final Map<String, dynamic> columns = row.toColumnMap();
      return StoredUser(
        id: _stringValue(columns['id']),
        sessionToken: _stringValue(columns['session_token']),
        email: _stringValue(columns['email']),
        displayName: _stringValue(columns['name']),
        passwordHash: _stringValue(columns['password']),
        gamesPlayed: _intValue(columns['games_played']),
        winRate: _doubleValue(columns['win_rate']),
        bestScore: 0,
        wins: _intValue(columns['wins']),
        losses: _intValue(columns['losses']),
        totalXp: _intValue(columns['total_xp']),
        clutchCorrectAnswers: 0,
        unlockedAchievementIds: <String>[],
        recentMatches: <StoredRecentMatch>[],
        settings: UserSettingsDto.defaults,
      );
    }).toList(growable: false);
    final Map<String, StoredUser> usersById = <String, StoredUser>{
      for (final StoredUser user in users) user.id: user,
    };

    final Result settingsRows = await connection.execute(
      '''
      SELECT user_id, theme_mode, language_code
      FROM settings
      ''',
    );
    for (final ResultRow row in settingsRows) {
      final Map<String, dynamic> columns = row.toColumnMap();
      final StoredUser? user = usersById[_stringValue(columns['user_id'])];
      if (user == null) {
        continue;
      }
      user.settings = UserSettingsDto(
        themeMode: _stringValue(columns['theme_mode']),
        languageCode: _stringValue(columns['language_code']),
      );
    }

    final Result achievementRows = await connection.execute(
      '''
      SELECT user_id, achivement_id
      FROM link_users_achivements
      ORDER BY user_id, achivement_id
      ''',
    );
    for (final ResultRow row in achievementRows) {
      final Map<String, dynamic> columns = row.toColumnMap();
      final StoredUser? user = usersById[_stringValue(columns['user_id'])];
      if (user == null) {
        continue;
      }
      user.unlockedAchievementIds.add(_stringValue(columns['achivement_id']));
    }

    final Result recentMatchRows = await connection.execute(
      '''
      SELECT
        user_id,
        room_name,
        score,
        won,
        mode,
        played_at_epoch_ms,
        was_host,
        clutch_answers
      FROM results
      ORDER BY user_id, result_order
      ''',
    );
    for (final ResultRow row in recentMatchRows) {
      final Map<String, dynamic> columns = row.toColumnMap();
      final StoredUser? user = usersById[_stringValue(columns['user_id'])];
      if (user == null) {
        continue;
      }
      user.recentMatches.add(
        StoredRecentMatch(
          roomName: _stringValue(columns['room_name']),
          score: _nullableIntValue(columns['score']),
          won: _boolValue(columns['won']),
          mode: _stringValue(columns['mode']),
          playedAtEpochMs: _intValue(columns['played_at_epoch_ms']),
          wasHost: _boolValue(columns['was_host']),
          clutchAnswers: _intValue(columns['clutch_answers']),
        ),
      );
      user.bestScore = max(
        user.bestScore,
        _nullableIntValue(columns['score']) ?? 0,
      );
      user.clutchCorrectAnswers += _intValue(columns['clutch_answers']);
    }

    for (final StoredUser user in users) {
      user.reconcileProfileStatsFromHistory();
    }

    return users;
  }

  Future<List<StoredRoom>> loadRooms() async {
    final Connection connection = await _requireConnection();
    final Result result = await connection.execute(
      '''
      SELECT
        id,
        code,
        name,
        topic,
        rounds,
        mode,
        max_players,
        password,
        host_user_id,
        package_file_name,
        status,
        phase,
        is_paused,
        round,
        current_chooser_id,
        question_owner_id,
        phase_seconds_left,
        phase_seconds_total,
        pending_answer_seconds_left,
        pending_answer_seconds_total,
        pending_answer_player_id,
        last_correct_answer_player_id,
        is_match_ended,
        winner_id,
        last_event,
        current_question_id,
        used_question_ids
      FROM rooms
      ORDER BY id
      ''',
    );
    final List<StoredRoom> rooms = result.map((ResultRow row) {
      final Map<String, dynamic> columns = row.toColumnMap();
      return StoredRoom(
        id: _stringValue(columns['id']),
        code: _stringValue(columns['code']),
        name: _stringValue(columns['name']),
        topic: _stringValue(columns['topic']),
        rounds: _intValue(columns['rounds']),
        mode: _stringValue(columns['mode']),
        maxPlayers: _intValue(columns['max_players']),
        password: _stringValue(columns['password']),
        hostUserId: _stringValue(columns['host_user_id']),
        packageFileName: _stringValue(columns['package_file_name']),
        status: _parseRoomLifecycleStatus(_stringValue(columns['status'])),
        hostDisconnectedAtEpochMs: null,
        participants: <StoredRoomParticipant>[],
        matchProgress: StoredMatchProgress(),
      );
    }).toList(growable: false);
    final Map<String, StoredRoom> roomsById = <String, StoredRoom>{
      for (final StoredRoom room in rooms) room.id: room,
    };
    final Map<String, _LoadedGameState> gameStatesByRoomId =
        <String, _LoadedGameState>{};
    for (final ResultRow row in result) {
      final Map<String, dynamic> columns = row.toColumnMap();
      final String phase = _stringValue(columns['phase']);
      if (phase.isEmpty) {
        continue;
      }
      gameStatesByRoomId[_stringValue(columns['id'])] = _LoadedGameState(
        phase: _parseGamePhase(phase),
        isPaused: _boolValue(columns['is_paused']),
        round: _nullableIntValue(columns['round']) ?? 1,
        currentChooserId: _stringValue(columns['current_chooser_id']),
        questionOwnerId: _stringValue(columns['question_owner_id']),
        phaseSecondsLeft: _intValue(columns['phase_seconds_left']),
        phaseSecondsTotal: _intValue(columns['phase_seconds_total']),
        pendingAnswerSecondsLeft:
            _intValue(columns['pending_answer_seconds_left']),
        pendingAnswerSecondsTotal:
            _intValue(columns['pending_answer_seconds_total']),
        pendingAnswerPlayerId:
            _nullableStringValue(columns['pending_answer_player_id']),
        lastCorrectAnswerPlayerId:
            _nullableStringValue(columns['last_correct_answer_player_id']),
        isMatchEnded: _boolValue(columns['is_match_ended']),
        winnerId: _nullableStringValue(columns['winner_id']),
        lastEvent: _stringValue(columns['last_event']),
        currentQuestionId: _nullableStringValue(columns['current_question_id']),
        usedQuestionIds:
            _decodeStringList(_stringValue(columns['used_question_ids'])),
      );
    }

    final Result participantRows = await connection.execute(
      '''
      SELECT room_id, user_id, display_name, is_connected, score
      FROM link_users_rooms
      ORDER BY room_id, participant_order
      ''',
    );
    for (final ResultRow row in participantRows) {
      final Map<String, dynamic> columns = row.toColumnMap();
      final StoredRoom? room = roomsById[_stringValue(columns['room_id'])];
      if (room == null) {
        continue;
      }
      room.participants.add(
        StoredRoomParticipant(
          userId: _stringValue(columns['user_id']),
          displayName: _stringValue(columns['display_name']),
          isConnected: _boolValue(columns['is_connected']),
          score: _intValue(columns['score']),
        ),
      );
    }

    final Result matchProgressRows = await connection.execute(
      '''
      SELECT room_id, profile_applied, ended_by_abandonment
      FROM room_match_progress
      ''',
    );
    for (final ResultRow row in matchProgressRows) {
      final Map<String, dynamic> columns = row.toColumnMap();
      final StoredRoom? room = roomsById[_stringValue(columns['room_id'])];
      if (room == null) {
        continue;
      }
      room.matchProgress = StoredMatchProgress(
        profileApplied: _boolValue(columns['profile_applied']),
        endedByAbandonment: _boolValue(columns['ended_by_abandonment']),
      );
    }

    final Result matchPlayerRows = await connection.execute(
      '''
      SELECT room_id, user_id, correct_answers, clutch_answers
      FROM room_match_player_stats
      ORDER BY room_id, user_id
      ''',
    );
    for (final ResultRow row in matchPlayerRows) {
      final Map<String, dynamic> columns = row.toColumnMap();
      final StoredRoom? room = roomsById[_stringValue(columns['room_id'])];
      if (room == null) {
        continue;
      }
      final String userId = _stringValue(columns['user_id']);
      room.matchProgress.correctAnswersByPlayerId[userId] =
          _intValue(columns['correct_answers']);
      room.matchProgress.clutchAnswersByPlayerId[userId] =
          _intValue(columns['clutch_answers']);
    }

    final Result flagRows = await connection.execute(
      '''
      SELECT room_id, user_id, flag_type
      FROM game_answer_flags
      ORDER BY room_id, flag_type, flag_order
      ''',
    );
    for (final ResultRow row in flagRows) {
      final Map<String, dynamic> columns = row.toColumnMap();
      final _LoadedGameState? gameState =
          gameStatesByRoomId[_stringValue(columns['room_id'])];
      if (gameState == null) {
        continue;
      }
      final String userId = _stringValue(columns['user_id']);
      if (_stringValue(columns['flag_type']) == 'passed') {
        gameState.passedPlayerIds.add(userId);
      } else {
        gameState.wrongAnswerPlayerIds.add(userId);
      }
    }

    for (final MapEntry<String, _LoadedGameState> entry
        in gameStatesByRoomId.entries) {
      final StoredRoom? room = roomsById[entry.key];
      if (room == null) {
        continue;
      }
      room.gameState = await entry.value.toGameState(room, _packageRepository);
    }

    return rooms;
  }

  Future<void> saveSnapshot({
    required List<StoredUser> users,
    required List<StoredRoom> rooms,
  }) async {
    final Connection connection = await _requireConnection();
    await connection.runTx((Session session) async {
      await session.execute('DELETE FROM game_answer_flags');
      await session.execute('DELETE FROM room_match_player_stats');
      await session.execute('DELETE FROM room_match_progress');
      await session.execute('DELETE FROM link_users_rooms');
      await session.execute('DELETE FROM rooms');
      await session.execute('DELETE FROM results');
      await session.execute('DELETE FROM link_users_achivements');
      await session.execute('DELETE FROM achivements');
      await session.execute('DELETE FROM settings');
      await session.execute('DELETE FROM users');

      await session.execute(
        Sql.named(
          '''
          INSERT INTO achivements (
            id,
            title_key,
            requirement_key,
            reward_xp
          ) VALUES
            (
              @firstWinId,
              'achievementFirstWinTitle',
              'achievementFirstWinRequirement',
              500
            ),
            (
              @clutchAnswerId,
              'achievementClutchAnswerTitle',
              'achievementClutchAnswerRequirement',
              750
            )
          ''',
        ),
        parameters: <String, Object?>{
          'firstWinId': _firstWinAchievementId,
          'clutchAnswerId': _clutchAnswerAchievementId,
        },
      );

      for (final StoredUser user in users) {
        await session.execute(
          Sql.named(
            '''
            INSERT INTO users (
              id,
              session_token,
              email,
              name,
              password,
              games_played,
              win_rate,
              wins,
              losses,
              total_xp,
              updated_at
            ) VALUES (
              @id,
              @sessionToken,
              @email,
              @displayName,
              @passwordHash,
              @gamesPlayed,
              @winRate,
              @wins,
              @losses,
              @totalXp,
              NOW()
            )
            ''',
          ),
          parameters: <String, Object?>{
            'id': user.id,
            'sessionToken': user.sessionToken,
            'email': user.email,
            'displayName': user.displayName,
            'passwordHash': user.passwordHash,
            'gamesPlayed': user.gamesPlayed,
            'winRate': user.winRate,
            'wins': user.wins,
            'losses': user.losses,
            'totalXp': user.totalXp,
          },
        );

        await session.execute(
          Sql.named(
            '''
            INSERT INTO settings (
              user_id,
              theme_mode,
              language_code
            ) VALUES (
              @userId,
              @themeMode,
              @languageCode
            )
            ''',
          ),
          parameters: <String, Object?>{
            'userId': user.id,
            'themeMode': user.settings.themeMode,
            'languageCode': user.settings.languageCode,
          },
        );

        for (int index = 0;
            index < user.unlockedAchievementIds.length;
            index++) {
          await session.execute(
            Sql.named(
              '''
              INSERT INTO link_users_achivements (
                user_id,
                achivement_id
              ) VALUES (
                @userId,
                @achievementId
              )
              ''',
            ),
            parameters: <String, Object?>{
              'userId': user.id,
              'achievementId': user.unlockedAchievementIds[index],
            },
          );
        }

        for (int index = 0; index < user.recentMatches.length; index++) {
          final StoredRecentMatch match = user.recentMatches[index];
          await session.execute(
            Sql.named(
              '''
              INSERT INTO results (
                user_id,
                result_order,
                room_name,
                score,
                won,
                mode,
                played_at_epoch_ms,
                was_host,
                clutch_answers
              ) VALUES (
                @userId,
                @matchOrder,
                @roomName,
                @score,
                @won,
                @mode,
                @playedAtEpochMs,
                @wasHost,
                @clutchAnswers
              )
              ''',
            ),
            parameters: <String, Object?>{
              'userId': user.id,
              'matchOrder': index,
              'roomName': match.roomName,
              'score': match.score,
              'won': match.won,
              'mode': match.mode,
              'playedAtEpochMs': match.playedAtEpochMs,
              'wasHost': match.wasHost,
              'clutchAnswers': match.clutchAnswers,
            },
          );
        }
      }

      for (final StoredRoom room in rooms) {
        await session.execute(
          Sql.named(
            '''
            INSERT INTO rooms (
              id,
              code,
              name,
              topic,
              rounds,
              mode,
              max_players,
              password,
              host_user_id,
              package_file_name,
              status,
              phase,
              is_paused,
              round,
              current_chooser_id,
              question_owner_id,
              phase_seconds_left,
              phase_seconds_total,
              pending_answer_seconds_left,
              pending_answer_seconds_total,
              pending_answer_player_id,
              last_correct_answer_player_id,
              is_match_ended,
              winner_id,
              last_event,
              current_question_id,
              used_question_ids,
              updated_at
            ) VALUES (
              @id,
              @code,
              @name,
              @topic,
              @rounds,
              @mode,
              @maxPlayers,
              @password,
              @hostUserId,
              @packageFileName,
              @status,
              @phase,
              @isPaused,
              @round,
              @currentChooserId,
              @questionOwnerId,
              @phaseSecondsLeft,
              @phaseSecondsTotal,
              @pendingAnswerSecondsLeft,
              @pendingAnswerSecondsTotal,
              @pendingAnswerPlayerId,
              @lastCorrectAnswerPlayerId,
              @isMatchEnded,
              @winnerId,
              @lastEvent,
              @currentQuestionId,
              @usedQuestionIds,
              NOW()
            )
            ''',
          ),
          parameters: <String, Object?>{
            'phase': room.gameState?.phase.name,
            'isPaused': room.gameState?.isPaused ?? false,
            'round': room.gameState?.round,
            'currentChooserId': room.gameState?.currentChooserId,
            'questionOwnerId': room.gameState?.questionOwnerId,
            'phaseSecondsLeft': room.gameState?.phaseSecondsLeft ?? 0,
            'phaseSecondsTotal': room.gameState?.phaseSecondsTotal ?? 0,
            'pendingAnswerSecondsLeft':
                room.gameState?.pendingAnswerSecondsLeft ?? 0,
            'pendingAnswerSecondsTotal':
                room.gameState?.pendingAnswerSecondsTotal ?? 0,
            'pendingAnswerPlayerId': room.gameState?.pendingAnswerPlayerId,
            'lastCorrectAnswerPlayerId':
                room.gameState?.lastCorrectAnswerPlayerId,
            'isMatchEnded': room.gameState?.isMatchEnded ?? false,
            'winnerId': room.gameState?.winnerId,
            'lastEvent': room.gameState?.lastEvent ?? '',
            'currentQuestionId': room.gameState?.currentQuestion?.id,
            'usedQuestionIds': _encodeStringList(
              room.gameState?.boardQuestions
                      .where((Question question) => question.used)
                      .map((Question question) => question.id) ??
                  const <String>[],
            ),
            'id': room.id,
            'code': room.code,
            'name': room.name,
            'topic': room.topic,
            'rounds': room.rounds,
            'mode': room.mode,
            'maxPlayers': room.maxPlayers,
            'password': room.password,
            'hostUserId': room.hostUserId,
            'packageFileName': room.packageFileName,
            'status': room.status.name,
          },
        );

        for (int index = 0; index < room.participants.length; index++) {
          final StoredRoomParticipant participant = room.participants[index];
          final int score = _scoreForParticipant(room.gameState, participant);
          await session.execute(
            Sql.named(
              '''
              INSERT INTO link_users_rooms (
                room_id,
                user_id,
                display_name,
                is_connected,
                participant_order,
                score
              ) VALUES (
                @roomId,
                @userId,
                @displayName,
                @isConnected,
                @participantOrder,
                @score
              )
              ''',
            ),
            parameters: <String, Object?>{
              'roomId': room.id,
              'userId': participant.userId,
              'displayName': participant.displayName,
              'isConnected': participant.isConnected,
              'participantOrder': index,
              'score': score,
            },
          );
        }

        await session.execute(
          Sql.named(
            '''
            INSERT INTO room_match_progress (
              room_id,
              profile_applied,
              ended_by_abandonment
            ) VALUES (
              @roomId,
              @profileApplied,
              @endedByAbandonment
            )
            ''',
          ),
          parameters: <String, Object?>{
            'roomId': room.id,
            'profileApplied': room.matchProgress.profileApplied,
            'endedByAbandonment': room.matchProgress.endedByAbandonment,
          },
        );

        final Set<String> playerIds = <String>{
          ...room.matchProgress.correctAnswersByPlayerId.keys,
          ...room.matchProgress.clutchAnswersByPlayerId.keys,
        };
        for (final String userId in playerIds) {
          await session.execute(
            Sql.named(
              '''
              INSERT INTO room_match_player_stats (
                room_id,
                user_id,
                correct_answers,
                clutch_answers
              ) VALUES (
                @roomId,
                @userId,
                @correctAnswers,
                @clutchAnswers
              )
              ''',
            ),
            parameters: <String, Object?>{
              'roomId': room.id,
              'userId': userId,
              'correctAnswers':
                  room.matchProgress.correctAnswersByPlayerId[userId] ?? 0,
              'clutchAnswers':
                  room.matchProgress.clutchAnswersByPlayerId[userId] ?? 0,
            },
          );
        }

        final GameState? gameState = room.gameState;
        if (gameState == null) {
          continue;
        }

        for (int index = 0; index < gameState.passedPlayerIds.length; index++) {
          await session.execute(
            Sql.named(
              '''
              INSERT INTO game_answer_flags (
                room_id,
                user_id,
                flag_type,
                flag_order
              ) VALUES (
                @roomId,
                @userId,
                'passed',
                @flagOrder
              )
              ''',
            ),
            parameters: <String, Object?>{
              'roomId': room.id,
              'userId': gameState.passedPlayerIds[index],
              'flagOrder': index,
            },
          );
        }

        for (int index = 0;
            index < gameState.wrongAnswerPlayerIds.length;
            index++) {
          await session.execute(
            Sql.named(
              '''
              INSERT INTO game_answer_flags (
                room_id,
                user_id,
                flag_type,
                flag_order
              ) VALUES (
                @roomId,
                @userId,
                'wrong',
                @flagOrder
              )
              ''',
            ),
            parameters: <String, Object?>{
              'roomId': room.id,
              'userId': gameState.wrongAnswerPlayerIds[index],
              'flagOrder': index,
            },
          );
        }
      }
    });
  }

  Future<Connection> _requireConnection() async {
    await open();
    return _connection!;
  }
}

class _LoadedGameState {
  _LoadedGameState({
    required this.phase,
    required this.isPaused,
    required this.round,
    required this.currentChooserId,
    required this.questionOwnerId,
    required this.phaseSecondsLeft,
    required this.phaseSecondsTotal,
    required this.pendingAnswerSecondsLeft,
    required this.pendingAnswerSecondsTotal,
    required this.pendingAnswerPlayerId,
    required this.lastCorrectAnswerPlayerId,
    required this.isMatchEnded,
    required this.winnerId,
    required this.lastEvent,
    required this.currentQuestionId,
    required this.usedQuestionIds,
  });

  final GamePhase phase;
  final bool isPaused;
  final int round;
  final String currentChooserId;
  final String questionOwnerId;
  final int phaseSecondsLeft;
  final int phaseSecondsTotal;
  final int pendingAnswerSecondsLeft;
  final int pendingAnswerSecondsTotal;
  final String? pendingAnswerPlayerId;
  final String? lastCorrectAnswerPlayerId;
  final bool isMatchEnded;
  final String? winnerId;
  final String lastEvent;
  final String? currentQuestionId;
  final List<String> usedQuestionIds;
  final List<String> passedPlayerIds = <String>[];
  final List<String> wrongAnswerPlayerIds = <String>[];

  Future<GameState> toGameState(
    StoredRoom room,
    _QuestionPackageRepository packageRepository,
  ) async {
    final List<Question> boardQuestions = await packageRepository.loadQuestions(
      room.packageFileName,
      rounds: room.rounds,
    );
    final Set<String> usedQuestionIdsSet = usedQuestionIds.toSet();
    final List<Question> hydratedQuestions = boardQuestions
        .map(
          (Question question) => question.copyWith(
            used: usedQuestionIdsSet.contains(question.id),
          ),
        )
        .toList(growable: false);
    final List<Player> players = room.participants
        .where(
          (StoredRoomParticipant participant) =>
              participant.userId != room.hostUserId,
        )
        .map(
          (StoredRoomParticipant participant) => Player(
            id: participant.userId,
            name: participant.displayName,
            score: participant.score,
          ),
        )
        .toList(growable: false);
    Question? currentQuestion;
    if (currentQuestionId != null) {
      for (final Question question in hydratedQuestions) {
        if (question.id == currentQuestionId) {
          currentQuestion = question;
          break;
        }
      }
    }
    return GameState(
      players: players,
      boardQuestions: hydratedQuestions,
      currentQuestion: currentQuestion,
      phase: phase,
      isPaused: isPaused,
      round: round,
      currentChooserId: currentChooserId,
      questionOwnerId: questionOwnerId,
      phaseSecondsLeft: phaseSecondsLeft,
      phaseSecondsTotal: phaseSecondsTotal,
      pendingAnswerSecondsLeft: pendingAnswerSecondsLeft,
      pendingAnswerSecondsTotal: pendingAnswerSecondsTotal,
      pendingAnswerPlayerId: pendingAnswerPlayerId,
      passedPlayerIds: passedPlayerIds,
      wrongAnswerPlayerIds: wrongAnswerPlayerIds,
      lastCorrectAnswerPlayerId: lastCorrectAnswerPlayerId,
      isMatchEnded: isMatchEnded,
      winnerId: winnerId,
      lastEvent: lastEvent,
    );
  }
}

class _QuestionPackageRepository {
  _QuestionPackageRepository({
    required Directory packageDirectory,
    required this.defaultPackageFileName,
  }) : _packageDirectory = packageDirectory;

  final Directory _packageDirectory;
  final String defaultPackageFileName;
  final Map<String, List<Question>> _cache = <String, List<Question>>{};

  Future<List<Question>> loadQuestions(
    String packageFileName, {
    required int rounds,
  }) async {
    final File file = await _resolveFile(packageFileName);
    final String cacheKey = file.path.toLowerCase();
    final List<Question>? cached = _cache[cacheKey];
    if (cached != null) {
      return _cloneQuestions(_filterQuestions(cached, rounds: rounds));
    }

    final Map<String, dynamic> json =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final List<Question> questions = <Question>[];
    final List<dynamic> roundEntries =
        json['rounds'] as List<dynamic>? ?? <dynamic>[];
    for (int roundIndex = 0; roundIndex < roundEntries.length; roundIndex++) {
      final Map<String, dynamic> roundJson =
          roundEntries[roundIndex] as Map<String, dynamic>;
      final int roundNumber =
          (roundJson['round'] as num?)?.toInt() ?? (roundIndex + 1);
      final List<dynamic> themes =
          roundJson['themes'] as List<dynamic>? ?? <dynamic>[];
      for (int themeIndex = 0; themeIndex < themes.length; themeIndex++) {
        final Map<String, dynamic> themeJson =
            themes[themeIndex] as Map<String, dynamic>;
        final String category = (themeJson['title'] as String? ?? '').trim();
        final List<dynamic> themeQuestions =
            themeJson['questions'] as List<dynamic>? ?? <dynamic>[];
        for (int questionIndex = 0;
            questionIndex < themeQuestions.length;
            questionIndex++) {
          final Map<String, dynamic> item =
              themeQuestions[questionIndex] as Map<String, dynamic>;
          final int value =
              (item['value'] as num?)?.toInt() ?? ((questionIndex + 1) * 100);
          final String id = (item['id'] as String? ?? '').trim().isEmpty
              ? 'r${roundNumber}_t${themeIndex + 1}_q${questionIndex + 1}'
              : (item['id'] as String).trim();
          questions.add(
            Question(
              id: id,
              text: item['text'] as String? ?? '',
              answer: item['answer'] as String? ?? '',
              category: category.isEmpty ? 'Theme ${themeIndex + 1}' : category,
              value: value,
              used: false,
              round: roundNumber,
            ),
          );
        }
      }
    }
    if (questions.isEmpty) {
      throw StateError('Question package "${file.path}" is empty.');
    }

    _cache[cacheKey] = questions;
    return _cloneQuestions(_filterQuestions(questions, rounds: rounds));
  }

  List<Question> _filterQuestions(
    List<Question> questions, {
    required int rounds,
  }) {
    final int effectiveRounds = rounds < 1 ? 1 : rounds;
    return questions
        .where((Question question) => question.round <= effectiveRounds)
        .toList(growable: false);
  }

  Future<File> _resolveFile(String requestedFileName) async {
    final String normalized = requestedFileName.trim().isEmpty
        ? defaultPackageFileName
        : requestedFileName.trim();
    final File explicitFile = File(normalized);
    if (await explicitFile.exists()) {
      return explicitFile;
    }

    final File packageFile = File(
      '${_packageDirectory.path}${Platform.pathSeparator}$normalized',
    );
    if (await packageFile.exists()) {
      return packageFile;
    }

    final File fallbackFile = File(
      '${_packageDirectory.path}${Platform.pathSeparator}$defaultPackageFileName',
    );
    if (await fallbackFile.exists()) {
      return fallbackFile;
    }

    throw StateError(
      'Question package "$normalized" was not found in '
      '"${_packageDirectory.path}".',
    );
  }

  List<Question> _cloneQuestions(List<Question> questions) {
    return questions
        .map(
          (Question question) => question.copyWith(
            used: false,
          ),
        )
        .toList(growable: false);
  }
}

RoomLifecycleStatus _parseRoomLifecycleStatus(String value) {
  return RoomLifecycleStatus.values.firstWhere(
    (RoomLifecycleStatus status) => status.name == value,
    orElse: () => RoomLifecycleStatus.waiting,
  );
}

GamePhase _parseGamePhase(String value) {
  return GamePhase.values.firstWhere(
    (GamePhase phase) => phase.name == value,
    orElse: () => GamePhase.waitingForHost,
  );
}

String _stringValue(Object? value) => value?.toString() ?? '';

String? _nullableStringValue(Object? value) {
  if (value == null) {
    return null;
  }
  final String stringValue = value.toString();
  return stringValue.isEmpty ? null : stringValue;
}

int _intValue(Object? value) {
  if (value == null) {
    return 0;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.parse(value.toString());
}

int? _nullableIntValue(Object? value) {
  if (value == null) {
    return null;
  }
  return _intValue(value);
}

double _doubleValue(Object? value) {
  if (value == null) {
    return 0;
  }
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.parse(value.toString());
}

bool _boolValue(Object? value) {
  if (value == null) {
    return false;
  }
  if (value is bool) {
    return value;
  }
  return value.toString().toLowerCase() == 'true';
}

String _encodeStringList(Iterable<String> values) => values.join('\n');

List<String> _decodeStringList(String raw) {
  if (raw.trim().isEmpty) {
    return <String>[];
  }
  return raw
      .split('\n')
      .where((String value) => value.trim().isNotEmpty)
      .toList(growable: false);
}

int _scoreForParticipant(
    GameState? gameState, StoredRoomParticipant participant) {
  if (gameState == null) {
    return 0;
  }
  for (final Player player in gameState.players) {
    if (player.id == participant.userId) {
      return player.score;
    }
  }
  return 0;
}

class StoredRecentMatch {
  StoredRecentMatch({
    required this.roomName,
    required this.won,
    required this.mode,
    required this.playedAtEpochMs,
    this.score,
    this.wasHost = false,
    this.clutchAnswers = 0,
  });

  factory StoredRecentMatch.fromJson(Map<String, dynamic> json) {
    return StoredRecentMatch(
      roomName: json['roomName'] as String? ?? '',
      score: (json['score'] as num?)?.toInt(),
      won: json['won'] as bool? ?? false,
      mode: json['mode'] as String? ?? 'multiplayer',
      playedAtEpochMs: (json['playedAtEpochMs'] as num?)?.toInt() ?? 0,
      wasHost: json['wasHost'] as bool? ?? false,
      clutchAnswers: (json['clutchAnswers'] as num?)?.toInt() ?? 0,
    );
  }

  final String roomName;
  final int? score;
  final bool won;
  final String mode;
  final int playedAtEpochMs;
  final bool wasHost;
  final int clutchAnswers;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'roomName': roomName,
        'score': score,
        'won': won,
        'mode': mode,
        'playedAtEpochMs': playedAtEpochMs,
        'wasHost': wasHost,
        'clutchAnswers': clutchAnswers,
      };

  ProfileRecentGame toProfileRecentGame() => ProfileRecentGame(
        roomName: roomName,
        score: score,
        won: won,
        mode: mode,
        playedAtEpochMs: playedAtEpochMs,
        wasHost: wasHost,
      );
}

class StoredMatchProgress {
  StoredMatchProgress({
    Map<String, int>? correctAnswersByPlayerId,
    Map<String, int>? clutchAnswersByPlayerId,
    this.profileApplied = false,
    this.endedByAbandonment = false,
  })  : correctAnswersByPlayerId = correctAnswersByPlayerId ?? <String, int>{},
        clutchAnswersByPlayerId = clutchAnswersByPlayerId ?? <String, int>{};

  factory StoredMatchProgress.fromJson(Map<String, dynamic> json) {
    return StoredMatchProgress(
      correctAnswersByPlayerId:
          ((json['correctAnswersByPlayerId'] as Map<String, dynamic>?) ??
                  <String, dynamic>{})
              .map((String key, dynamic value) =>
                  MapEntry(key, (value as num).toInt())),
      clutchAnswersByPlayerId:
          ((json['clutchAnswersByPlayerId'] as Map<String, dynamic>?) ??
                  <String, dynamic>{})
              .map((String key, dynamic value) =>
                  MapEntry(key, (value as num).toInt())),
      profileApplied: json['profileApplied'] as bool? ?? false,
      endedByAbandonment: json['endedByAbandonment'] as bool? ?? false,
    );
  }

  final Map<String, int> correctAnswersByPlayerId;
  final Map<String, int> clutchAnswersByPlayerId;
  bool profileApplied;
  bool endedByAbandonment;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'correctAnswersByPlayerId': correctAnswersByPlayerId,
        'clutchAnswersByPlayerId': clutchAnswersByPlayerId,
        'profileApplied': profileApplied,
        'endedByAbandonment': endedByAbandonment,
      };
}

class StoredUser {
  StoredUser({
    required this.id,
    required this.sessionToken,
    required this.email,
    required this.displayName,
    required this.passwordHash,
    required this.gamesPlayed,
    required this.winRate,
    required this.bestScore,
    required this.wins,
    required this.losses,
    required this.totalXp,
    required this.clutchCorrectAnswers,
    required this.unlockedAchievementIds,
    required this.recentMatches,
    required this.settings,
  });

  factory StoredUser.fromJson(Map<String, dynamic> json) {
    final int gamesPlayed = (json['gamesPlayed'] as num?)?.toInt() ?? 0;
    final double winRate = (json['winRate'] as num?)?.toDouble() ?? 0;
    final int derivedWins = min(
      gamesPlayed,
      max(0, (gamesPlayed * winRate).round()),
    );
    final int wins = (json['wins'] as num?)?.toInt() ?? derivedWins;
    final int losses =
        (json['losses'] as num?)?.toInt() ?? max(0, gamesPlayed - wins);
    return StoredUser(
      id: json['id'] as String? ?? '',
      sessionToken: json['sessionToken'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      passwordHash: json['passwordHash'] as String? ?? '',
      gamesPlayed: gamesPlayed,
      winRate: winRate,
      bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
      wins: wins,
      losses: losses,
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      clutchCorrectAnswers:
          (json['clutchCorrectAnswers'] as num?)?.toInt() ?? 0,
      unlockedAchievementIds:
          ((json['unlockedAchievementIds'] as List<dynamic>?) ?? <dynamic>[])
              .map((dynamic item) => item as String)
              .toList(),
      recentMatches: ((json['recentMatches'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic item) =>
              StoredRecentMatch.fromJson(item as Map<String, dynamic>))
          .toList(),
      settings: UserSettingsDto.fromJson(
        json['settings'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }

  final String id;
  String sessionToken;
  final String email;
  String displayName;
  final String passwordHash;
  int gamesPlayed;
  double winRate;
  int bestScore;
  int wins;
  int losses;
  int totalXp;
  int clutchCorrectAnswers;
  final List<String> unlockedAchievementIds;
  final List<StoredRecentMatch> recentMatches;
  UserSettingsDto settings;

  void reconcileProfileStatsFromHistory() {
    gamesPlayed = max(gamesPlayed, recentMatches.length);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'sessionToken': sessionToken,
        'email': email,
        'displayName': displayName,
        'passwordHash': passwordHash,
        'gamesPlayed': gamesPlayed,
        'winRate': winRate,
        'bestScore': bestScore,
        'wins': wins,
        'losses': losses,
        'totalXp': totalXp,
        'clutchCorrectAnswers': clutchCorrectAnswers,
        'unlockedAchievementIds': unlockedAchievementIds,
        'recentMatches': recentMatches
            .map((StoredRecentMatch game) => game.toJson())
            .toList(),
        'settings': settings.toJson(),
      };

  AuthSession toSession() => AuthSession(
        playerId: id,
        sessionToken: sessionToken,
        displayName: displayName,
        email: email,
      );

  ProfileSummary toProfile() => ProfileSummary(
        displayName: displayName,
        gamesPlayed: gamesPlayed,
        winRate: winRate,
        bestScore: bestScore,
        wins: wins,
        losses: losses,
        totalXp: totalXp,
        clutchCorrectAnswers: clutchCorrectAnswers,
        unlockedAchievementIds:
            List<String>.unmodifiable(unlockedAchievementIds),
        recentGames: recentMatches
            .take(_recentMatchesLimit)
            .map((StoredRecentMatch game) => game.toProfileRecentGame())
            .toList(growable: false),
      );
}

class StoredRoom {
  StoredRoom({
    required this.id,
    required this.code,
    required this.name,
    required this.topic,
    required this.rounds,
    required this.mode,
    required this.maxPlayers,
    required this.password,
    required this.hostUserId,
    required this.packageFileName,
    required this.status,
    required this.participants,
    required this.matchProgress,
    this.hostDisconnectedAtEpochMs,
    this.gameState,
  });

  factory StoredRoom.fromJson(Map<String, dynamic> json) {
    return StoredRoom(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      rounds: (json['rounds'] as num?)?.toInt() ?? 3,
      mode: json['mode'] as String? ?? 'multiplayer',
      maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 4,
      password: json['password'] as String? ?? '',
      hostUserId: json['hostUserId'] as String? ?? '',
      packageFileName: json['packageFileName'] as String? ?? '',
      hostDisconnectedAtEpochMs:
          (json['hostDisconnectedAtEpochMs'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
      status: RoomLifecycleStatus.values.firstWhere(
        (RoomLifecycleStatus value) =>
            value.name == (json['status'] as String? ?? ''),
        orElse: () => RoomLifecycleStatus.waiting,
      ),
      gameState: json['gameState'] is Map<String, dynamic>
          ? GameState.fromJson(json['gameState'] as Map<String, dynamic>)
          : null,
      matchProgress: json['matchProgress'] is Map<String, dynamic>
          ? StoredMatchProgress.fromJson(
              json['matchProgress'] as Map<String, dynamic>,
            )
          : StoredMatchProgress(),
      participants: ((json['participants'] as List<dynamic>? ?? <dynamic>[]))
          .map(
            (dynamic item) => StoredRoomParticipant.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  final String id;
  final String code;
  final String name;
  final String topic;
  final int rounds;
  final String mode;
  final int maxPlayers;
  final String password;
  String hostUserId;
  final String packageFileName;
  int? hostDisconnectedAtEpochMs;
  RoomLifecycleStatus status;
  final List<StoredRoomParticipant> participants;
  StoredMatchProgress matchProgress;
  GameState? gameState;

  int get playerCount => participants
      .where((StoredRoomParticipant participant) =>
          participant.userId != hostUserId)
      .length;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'code': code,
        'name': name,
        'topic': topic,
        'rounds': rounds,
        'mode': mode,
        'maxPlayers': maxPlayers,
        'password': password,
        'hostUserId': hostUserId,
        'packageFileName': packageFileName,
        'hostDisconnectedAtEpochMs': hostDisconnectedAtEpochMs,
        'status': status.name,
        'gameState': gameState?.toJson(),
        'matchProgress': matchProgress.toJson(),
        'participants': participants
            .map((StoredRoomParticipant participant) => participant.toJson())
            .toList(),
      };
}

class StoredRoomParticipant {
  StoredRoomParticipant({
    required this.userId,
    required this.displayName,
    required this.isConnected,
    this.score = 0,
  });

  factory StoredRoomParticipant.fromJson(Map<String, dynamic> json) {
    return StoredRoomParticipant(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      isConnected: json['isConnected'] as bool? ?? false,
      score: (json['score'] as num?)?.toInt() ?? 0,
    );
  }

  final String userId;
  final String displayName;
  bool isConnected;
  int score;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userId': userId,
        'displayName': displayName,
        'isConnected': isConnected,
        'score': score,
      };
}
