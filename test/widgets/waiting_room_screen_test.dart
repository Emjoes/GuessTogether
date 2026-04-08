import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:guesstogether/core/l10n/app_locale.dart';
import 'package:guesstogether/data/api/app_backend_api.dart';
import 'package:guesstogether/data/api/backend_models.dart';
import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/lobby/presentation/waiting_room_screen.dart';
import 'package:guesstogether/features/session/app_session_controller.dart';
import '../test_app.dart';

class _FakeWaitingRoomApi implements AppBackendApi {
  _FakeWaitingRoomApi({
    required this.room,
    required this.messages,
    this.startErrorText,
  });

  final RoomDetails room;
  final StreamController<RoomRealtimeMessage> messages;
  final String? startErrorText;

  @override
  RoomRealtimeConnection connectToRoom(String roomId) {
    return RoomRealtimeConnection(
      messages: messages.stream,
      onClose: () async {},
    );
  }

  @override
  Future<RoomDetails> loadRoom(String roomId) async => room;

  @override
  Future<void> leaveRoom(String roomId) async {}

  @override
  Future<void> startRoom(String roomId) async {
    if (startErrorText != null) {
      throw BackendException(startErrorText!);
    }
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
      String roomId, String playerId, int score) async {}

  @override
  Future<void> skipQuestion(String roomId) async {}

  @override
  Future<void> skipRound(String roomId) async {}

  @override
  Future<void> togglePause(String roomId) async {}
}

class _FakeAppSessionController extends AppSessionController {
  _FakeAppSessionController(this._sessionState);

  final AppSessionState _sessionState;

  @override
  Future<AppSessionState> build() async => _sessionState;
}

RoomDetails _buildRoom({
  required int currentPlayers,
}) {
  final List<RoomParticipant> participants = <RoomParticipant>[
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
  ];

  if (currentPlayers >= 2) {
    participants.add(
      const RoomParticipant(
        id: 'p2',
        displayName: 'Bob',
        isHost: false,
        isConnected: true,
      ),
    );
  }

  return RoomDetails(
    summary: RoomSummary(
      id: 'room-1',
      code: '1234',
      name: 'Arena',
      topic: 'General',
      rounds: 3,
      mode: 'multiplayer',
      currentPlayers: currentPlayers,
      maxPlayers: 4,
      requiresPassword: false,
      lifecycleStatus: RoomLifecycleStatus.waiting,
      isHost: false,
    ),
    hostPlayerId: 'host-1',
    roomPassword: '',
    packageFileName: 'general_quiz_pack.json',
    participants: participants,
  );
}

AppSessionState _sessionState(String playerId) {
  return AppSessionState(
    session: AuthSession(
      playerId: playerId,
      sessionToken: 'session-token',
      displayName: playerId == 'host-1' ? 'Host' : 'Alice',
      email: '$playerId@example.com',
    ),
    profile: null,
    themeMode: ThemeMode.light,
    appLanguage: AppLanguage.english,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('WaitingRoomScreen shows host-start text for players',
      (tester) async {
    final StreamController<RoomRealtimeMessage> messages =
        StreamController<RoomRealtimeMessage>.broadcast();
    addTearDown(messages.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appBackendApiProvider.overrideWithValue(
            _FakeWaitingRoomApi(
              room: _buildRoom(currentPlayers: 2),
              messages: messages,
            ),
          ),
          appSessionControllerProvider.overrideWith(
            () => _FakeAppSessionController(_sessionState('p1')),
          ),
        ],
        child: buildTestMaterialApp(
          home: const WaitingRoomScreen(roomId: 'room-1'),
          locale: const Locale('en'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Host must start the match'), findsOneWidget);
    expect(find.text('Package: Standard'), findsOneWidget);
  });

  testWidgets('WaitingRoomScreen does not show host-start text for host',
      (tester) async {
    final StreamController<RoomRealtimeMessage> messages =
        StreamController<RoomRealtimeMessage>.broadcast();
    addTearDown(messages.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appBackendApiProvider.overrideWithValue(
            _FakeWaitingRoomApi(
              room: _buildRoom(currentPlayers: 2),
              messages: messages,
            ),
          ),
          appSessionControllerProvider.overrideWith(
            () => _FakeAppSessionController(_sessionState('host-1')),
          ),
        ],
        child: buildTestMaterialApp(
          home: const WaitingRoomScreen(roomId: 'room-1'),
          locale: const Locale('en'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Host must start the match'), findsNothing);
  });

  testWidgets('WaitingRoomScreen shows min players text when room cannot start',
      (tester) async {
    final StreamController<RoomRealtimeMessage> messages =
        StreamController<RoomRealtimeMessage>.broadcast();
    addTearDown(messages.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appBackendApiProvider.overrideWithValue(
            _FakeWaitingRoomApi(
              room: _buildRoom(currentPlayers: 1),
              messages: messages,
            ),
          ),
          appSessionControllerProvider.overrideWith(
            () => _FakeAppSessionController(_sessionState('p1')),
          ),
        ],
        child: buildTestMaterialApp(
          home: const WaitingRoomScreen(roomId: 'room-1'),
          locale: const Locale('en'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('At least 2 players besides the host are required to start'),
      findsOneWidget,
    );
  });

  testWidgets('WaitingRoomScreen shows backend start error for host',
      (tester) async {
    final StreamController<RoomRealtimeMessage> messages =
        StreamController<RoomRealtimeMessage>.broadcast();
    addTearDown(messages.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appBackendApiProvider.overrideWithValue(
            _FakeWaitingRoomApi(
              room: _buildRoom(currentPlayers: 2),
              messages: messages,
              startErrorText: 'Need one more player',
            ),
          ),
          appSessionControllerProvider.overrideWith(
            () => _FakeAppSessionController(_sessionState('host-1')),
          ),
        ],
        child: buildTestMaterialApp(
          home: const WaitingRoomScreen(roomId: 'room-1'),
          locale: const Locale('en'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Start match'));
    await tester.pumpAndSettle();

    expect(find.text('Need one more player'), findsOneWidget);
  });

  testWidgets('Host back action opens room destruction confirmation',
      (tester) async {
    final StreamController<RoomRealtimeMessage> messages =
        StreamController<RoomRealtimeMessage>.broadcast();
    addTearDown(messages.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appBackendApiProvider.overrideWithValue(
            _FakeWaitingRoomApi(
              room: _buildRoom(currentPlayers: 2),
              messages: messages,
            ),
          ),
          appSessionControllerProvider.overrideWith(
            () => _FakeAppSessionController(_sessionState('host-1')),
          ),
        ],
        child: buildTestMaterialApp(
          home: const WaitingRoomScreen(roomId: 'room-1'),
          locale: const Locale('en'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Leave match?'), findsOneWidget);
    expect(
      find.text(
        'If the host leaves, the room will be destroyed for all players.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Host app bar back button opens room destruction confirmation',
      (tester) async {
    final StreamController<RoomRealtimeMessage> messages =
        StreamController<RoomRealtimeMessage>.broadcast();
    addTearDown(messages.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appBackendApiProvider.overrideWithValue(
            _FakeWaitingRoomApi(
              room: _buildRoom(currentPlayers: 2),
              messages: messages,
            ),
          ),
          appSessionControllerProvider.overrideWith(
            () => _FakeAppSessionController(_sessionState('host-1')),
          ),
        ],
        child: buildTestMaterialApp(
          home: const WaitingRoomScreen(roomId: 'room-1'),
          locale: const Locale('en'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Leave match?'), findsOneWidget);
    expect(
      find.text(
        'If the host leaves, the room will be destroyed for all players.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Players see host-left message when waiting room is closed',
      (tester) async {
    final StreamController<RoomRealtimeMessage> messages =
        StreamController<RoomRealtimeMessage>.broadcast();
    addTearDown(messages.close);

    final GoRouter router = GoRouter(
      initialLocation: WaitingRoomScreen.routeLocation('room-1'),
      routes: <RouteBase>[
        GoRoute(
          path: WaitingRoomScreen.routePath,
          builder: (context, state) => WaitingRoomScreen(
            roomId: state.pathParameters['roomId'] ?? '',
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Home')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appBackendApiProvider.overrideWithValue(
            _FakeWaitingRoomApi(
              room: _buildRoom(currentPlayers: 2),
              messages: messages,
            ),
          ),
          appSessionControllerProvider.overrideWith(
            () => _FakeAppSessionController(_sessionState('p1')),
          ),
        ],
        child: buildTestMaterialAppRouter(
          routerConfig: router,
          locale: const Locale('en'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    messages.add(
      RoomRealtimeMessage(
        type: 'room_closed',
        room: _buildRoom(currentPlayers: 2),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Host left the game - match was ended'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
