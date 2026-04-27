import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guesstogether/data/api/app_backend_api.dart';
import 'package:guesstogether/data/api/backend_models.dart';
import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/lobby/providers/create_room_provider.dart';
import 'package:guesstogether/features/lobby/providers/room_session_provider.dart';
import 'package:guesstogether/features/session/app_session_controller.dart';

class _FakeWaitingRoomApi implements AppBackendApi {
  _FakeWaitingRoomApi({
    required this.room,
    required this.messages,
  });

  RoomDetails room;
  final StreamController<RoomRealtimeMessage> messages;
  Object? loadRoomError;
  int loadRoomCalls = 0;
  int connectCalls = 0;
  int closeCalls = 0;
  int leaveRoomCalls = 0;

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
  Future<RoomDetails> loadRoom(String roomId) async {
    loadRoomCalls += 1;
    if (loadRoomError != null) {
      throw loadRoomError!;
    }
    return room;
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    leaveRoomCalls += 1;
  }

  @override
  Future<void> acceptAnswer(String roomId) async {}

  @override
  Future<void> chooseQuestion(String roomId, String questionId) async {}

  @override
  Future<RoomSummary> createRoom(CreateRoomRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard(LeaderboardScope scope) {
    throw UnimplementedError();
  }

  @override
  Future<AppVersionStatus> loadAppVersionStatus() async {
    return const AppVersionStatus(
      latestVersion: '1.0.1',
      minimumSupportedVersion: '1.0.1',
    );
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
  Future<RoomSummary> joinRoom(
    String code, {
    required String playerName,
    String? password,
  }) {
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
    String roomId,
    String playerId,
    int score,
  ) async {}

  @override
  Future<void> skipQuestion(String roomId) async {}

  @override
  Future<void> skipRound(String roomId) async {}

  @override
  Future<void> startRoom(String roomId) async {}

  @override
  Future<void> togglePause(String roomId) async {}
}

RoomDetails _buildRoom({
  RoomLifecycleStatus lifecycleStatus = RoomLifecycleStatus.waiting,
  bool secondPlayerConnected = true,
}) {
  return RoomDetails(
    summary: RoomSummary(
      id: 'room-1',
      code: '1234',
      name: 'Arena',
      topic: 'General',
      rounds: 3,
      mode: 'multiplayer',
      currentPlayers: 2,
      maxPlayers: 4,
      requiresPassword: false,
      lifecycleStatus: lifecycleStatus,
      isHost: false,
    ),
    hostPlayerId: 'host-1',
    roomPassword: '',
    packageFileName: defaultRoomPackageFileName,
    participants: <RoomParticipant>[
      const RoomParticipant(
        id: 'host-1',
        displayName: 'Host',
        isHost: true,
        isConnected: true,
      ),
      const RoomParticipant(
        id: 'p1',
        displayName: 'Alice',
        isHost: false,
        isConnected: true,
      ),
      RoomParticipant(
        id: 'p2',
        displayName: 'Bob',
        isHost: false,
        isConnected: secondPlayerConnected,
      ),
    ],
  );
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('resume reloads latest room snapshot and reconnects realtime', () async {
    final StreamController<RoomRealtimeMessage> messages =
        StreamController<RoomRealtimeMessage>.broadcast();
    final _FakeWaitingRoomApi api = _FakeWaitingRoomApi(
      room: _buildRoom(),
      messages: messages,
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appBackendApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await messages.close();
    });

    final ProviderSubscription<WaitingRoomState> subscription =
        container.listen(
      waitingRoomControllerProvider('room-1'),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await _flushAsync();
    expect(api.loadRoomCalls, 1);
    expect(api.connectCalls, 1);

    api.room = _buildRoom(
      lifecycleStatus: RoomLifecycleStatus.inGame,
      secondPlayerConnected: false,
    );

    final WaitingRoomController controller =
        container.read(waitingRoomControllerProvider('room-1').notifier);
    await controller.resyncAfterResume();
    await _flushAsync();

    final WaitingRoomState state =
        container.read(waitingRoomControllerProvider('room-1'));
    expect(api.loadRoomCalls, 2);
    expect(api.connectCalls, 2);
    expect(api.closeCalls, 1);
    expect(state.room, api.room);
    expect(state.hasStarted, isTrue);
    expect(container.read(activeRoomProvider), api.room);
  });

  test('resume closes waiting room when backend reports it missing', () async {
    final StreamController<RoomRealtimeMessage> messages =
        StreamController<RoomRealtimeMessage>.broadcast();
    final _FakeWaitingRoomApi api = _FakeWaitingRoomApi(
      room: _buildRoom(),
      messages: messages,
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appBackendApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await messages.close();
    });

    final ProviderSubscription<WaitingRoomState> subscription =
        container.listen(
      waitingRoomControllerProvider('room-1'),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await _flushAsync();
    api.loadRoomError = const BackendException(
      'Room not found',
      statusCode: 404,
    );

    final WaitingRoomController controller =
        container.read(waitingRoomControllerProvider('room-1').notifier);
    await controller.resyncAfterResume();
    await _flushAsync();

    final WaitingRoomState state =
        container.read(waitingRoomControllerProvider('room-1'));
    expect(state.room, isNull);
    expect(state.errorText, 'room_closed');
    expect(container.read(activeRoomProvider), isNull);
  });

  test('host detach leaves room and closes realtime', () async {
    final StreamController<RoomRealtimeMessage> messages =
        StreamController<RoomRealtimeMessage>.broadcast();
    final _FakeWaitingRoomApi api = _FakeWaitingRoomApi(
      room: _buildRoom(),
      messages: messages,
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appBackendApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await messages.close();
    });

    final ProviderSubscription<WaitingRoomState> subscription =
        container.listen(
      waitingRoomControllerProvider('room-1'),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await _flushAsync();

    final WaitingRoomController controller =
        container.read(waitingRoomControllerProvider('room-1').notifier);
    await controller.handleAppDetached(isHost: true);
    await _flushAsync();

    expect(api.leaveRoomCalls, 1);
    expect(api.closeCalls, 1);
    expect(container.read(activeRoomProvider), isNull);
  });

  test('player detach only disconnects realtime', () async {
    final StreamController<RoomRealtimeMessage> messages =
        StreamController<RoomRealtimeMessage>.broadcast();
    final _FakeWaitingRoomApi api = _FakeWaitingRoomApi(
      room: _buildRoom(),
      messages: messages,
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appBackendApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await messages.close();
    });

    final ProviderSubscription<WaitingRoomState> subscription =
        container.listen(
      waitingRoomControllerProvider('room-1'),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await _flushAsync();

    final WaitingRoomController controller =
        container.read(waitingRoomControllerProvider('room-1').notifier);
    await controller.handleAppDetached(isHost: false);
    await _flushAsync();

    expect(api.leaveRoomCalls, 0);
    expect(api.closeCalls, 1);
    expect(container.read(activeRoomProvider), isNotNull);
  });
}
