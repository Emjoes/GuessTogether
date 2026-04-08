import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/data/api/app_backend_api.dart';
import 'package:guesstogether/data/api/backend_models.dart';
import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/game/domain/game_models.dart';
import 'package:guesstogether/features/game/providers/game_providers.dart';
import 'package:guesstogether/features/lobby/providers/room_session_provider.dart';
import 'package:guesstogether/features/session/app_session_controller.dart';

class _FakeRealtimeApi implements AppBackendApi {
  _FakeRealtimeApi({
    required this.room,
    required this.messages,
  });

  final RoomDetails room;
  final StreamController<RoomRealtimeMessage> messages;
  int connectCalls = 0;
  int closeCalls = 0;

  @override
  RoomRealtimeConnection connectToRoom(String roomId) {
    connectCalls += 1;
    return RoomRealtimeConnection(
      messages: messages.stream,
      onClose: () async {
        closeCalls += 1;
      },
    );
  }

  @override
  Future<RoomDetails> loadRoom(String roomId) async => room;

  @override
  Future<void> acceptAnswer(String roomId) async {}

  @override
  Future<void> chooseQuestion(String roomId, String questionId) async {}

  @override
  Future<RoomSummary> createRoom(CreateRoomRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<void> leaveRoom(String roomId) async {}

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard(LeaderboardScope scope) {
    throw UnimplementedError();
  }

  @override
  Future<BootstrapPayload> loadBootstrap() {
    throw UnimplementedError();
  }

  @override
  Future<ProfileSummary> loadProfile() {
    throw UnimplementedError();
  }

  @override
  Future<List<RoomSummary>> loadRooms() {
    throw UnimplementedError();
  }

  @override
  Future<BootstrapPayload> login(LoginRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<void> passQuestion(String roomId) async {}

  @override
  Future<BootstrapPayload> register(RegisterRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<void> rejectAnswer(String roomId) async {}

  @override
  Future<void> requestAnswer(String roomId) async {}

  @override
  Future<void> saveSettings(UserSettingsDto settings) async {}

  @override
  Future<void> setPlayerScore(
      String roomId, String playerId, int score) async {}

  @override
  Future<void> skipQuestion(String roomId) async {}

  @override
  Future<void> skipRound(String roomId) async {}

  @override
  Future<void> startRoom(String roomId) async {}

  @override
  Future<void> togglePause(String roomId) async {}

  @override
  Future<RoomSummary> joinRoom(
    String code, {
    required String playerName,
    String? password,
  }) {
    throw UnimplementedError();
  }
}

RoomDetails _buildRoom({
  String roomId = 'room-1',
  String roomName = 'Arena',
  GameState? gameState,
}) {
  return RoomDetails(
    summary: RoomSummary(
      id: roomId,
      code: '1234',
      name: roomName,
      topic: 'general',
      rounds: 3,
      mode: 'classic',
      currentPlayers: 2,
      maxPlayers: 6,
      requiresPassword: false,
      lifecycleStatus: RoomLifecycleStatus.inGame,
      isHost: true,
    ),
    hostPlayerId: 'host-1',
    roomPassword: '',
    packageFileName: 'pack.json',
    gameState: gameState,
    participants: const <RoomParticipant>[
      RoomParticipant(
        id: 'host-1',
        displayName: 'Host',
        isHost: true,
        isConnected: true,
      ),
      RoomParticipant(
        id: 'p1',
        displayName: 'Alice',
        isHost: false,
        isConnected: true,
      ),
      RoomParticipant(
        id: 'p2',
        displayName: 'Bob',
        isHost: false,
        isConnected: true,
      ),
    ],
  );
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('game controller is not recreated when active room changes', () async {
    final StreamController<RoomRealtimeMessage> messages =
        StreamController<RoomRealtimeMessage>.broadcast();
    final RoomDetails initialRoom = _buildRoom(
      gameState: GameState.initial(
        players: const <Player>[
          Player(id: 'p1', name: 'Alice', score: 0),
          Player(id: 'p2', name: 'Bob', score: 0),
        ],
      ),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appBackendApiProvider.overrideWithValue(
          _FakeRealtimeApi(room: initialRoom, messages: messages),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await messages.close();
    });

    container.read(activeRoomProvider.notifier).state = initialRoom;
    final ProviderSubscription<GameState> subscription = container.listen(
      gameControllerProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final GameController firstController =
        container.read(gameControllerProvider.notifier);
    await _flushAsync();

    container.read(activeRoomProvider.notifier).state = _buildRoom(
      roomName: 'Arena Reloaded',
      gameState: initialRoom.gameState,
    );
    await _flushAsync();

    final GameController secondController =
        container.read(gameControllerProvider.notifier);
    expect(identical(firstController, secondController), isTrue);
  });

  test('room_closed realtime message clears active room and closes match',
      () async {
    final StreamController<RoomRealtimeMessage> messages =
        StreamController<RoomRealtimeMessage>.broadcast();
    final RoomDetails room = _buildRoom(
      gameState: GameState.initial(
        players: const <Player>[
          Player(id: 'p1', name: 'Alice', score: 0),
          Player(id: 'p2', name: 'Bob', score: 0),
        ],
      ),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appBackendApiProvider.overrideWithValue(
          _FakeRealtimeApi(room: room, messages: messages),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await messages.close();
    });

    container.read(activeRoomProvider.notifier).state = room;
    final ProviderSubscription<GameState> subscription = container.listen(
      gameControllerProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await _flushAsync();
    expect(container.read(activeRoomProvider)?.summary.id, room.summary.id);
    expect(container.read(matchRoomClosedProvider), isFalse);
    expect(container.read(matchRoomClosedReasonProvider), isNull);

    messages.add(RoomRealtimeMessage(type: 'room_closed', room: room));
    await _flushAsync();

    expect(container.read(activeRoomProvider), isNull);
    expect(container.read(matchRoomClosedProvider), isTrue);
    expect(
      container.read(matchRoomClosedReasonProvider),
      MatchRoomClosedReason.hostLeft,
    );
  });

  test('finished realtime state disconnects updates and keeps final results',
      () async {
    final StreamController<RoomRealtimeMessage> messages =
        StreamController<RoomRealtimeMessage>.broadcast();
    final GameState initialState = GameState.initial(
      players: const <Player>[
        Player(id: 'p1', name: 'Alice', score: 0),
        Player(id: 'p2', name: 'Bob', score: 0),
      ],
    );
    final RoomDetails room = _buildRoom(gameState: initialState);
    final _FakeRealtimeApi api =
        _FakeRealtimeApi(room: room, messages: messages);
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appBackendApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await messages.close();
    });

    container.read(activeRoomProvider.notifier).state = room;
    final ProviderSubscription<GameState> subscription = container.listen(
      gameControllerProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await _flushAsync();
    expect(api.connectCalls, 1);

    final GameState finishedState = initialState.copyWith(
      players: const <Player>[
        Player(id: 'p1', name: 'Alice', score: 200),
        Player(id: 'p2', name: 'Bob', score: 100),
      ],
      phase: GamePhase.finished,
      isMatchEnded: true,
      winnerId: 'p1',
    );

    messages.add(
      RoomRealtimeMessage(
        type: 'game_state',
        room: _buildRoom(gameState: finishedState),
        gameState: finishedState,
      ),
    );
    await _flushAsync();

    expect(container.read(gameControllerProvider), finishedState);
    expect(api.closeCalls, 1);
    expect(container.read(matchRoomClosedProvider), isFalse);

    final GameState mutatedState = finishedState.copyWith(
      players: const <Player>[
        Player(id: 'p1', name: 'Alice', score: -500),
        Player(id: 'p2', name: 'Bob', score: 999),
      ],
      winnerId: 'p2',
    );

    messages.add(
      RoomRealtimeMessage(
        type: 'game_state',
        room: _buildRoom(gameState: mutatedState),
        gameState: mutatedState,
      ),
    );
    await _flushAsync();

    expect(container.read(gameControllerProvider), finishedState);
    expect(api.closeCalls, 1);
  });
}
