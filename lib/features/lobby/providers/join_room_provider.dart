import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/data/api/mock_http_adapter.dart';

const Object _unset = Object();

enum LobbyType { multiplayer, duel }

enum JoinLobbyResult { success, invalidPassword, failed }

class LobbyRoom {
  const LobbyRoom({
    required this.id,
    required this.code,
    required this.name,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.type,
    required this.requiresPassword,
    this.password,
  });

  final String id;
  final String code;
  final String name;
  final int currentPlayers;
  final int maxPlayers;
  final LobbyType type;
  final bool requiresPassword;
  final String? password;
}

final joinRoomControllerProvider =
    StateNotifierProvider<JoinRoomController, JoinRoomState>(
  (ref) => JoinRoomController(MockHttpAdapter()),
);

class JoinRoomState {
  JoinRoomState({
    List<LobbyRoom>? rooms,
    this.isLoading = false,
    this.errorText,
    this.joiningRoomId,
  }) : rooms = rooms ?? _mockLobbies;

  final List<LobbyRoom> rooms;
  final bool isLoading;
  final String? errorText;
  final String? joiningRoomId;

  JoinRoomState copyWith({
    List<LobbyRoom>? rooms,
    bool? isLoading,
    Object? errorText = _unset,
    Object? joiningRoomId = _unset,
  }) {
    return JoinRoomState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      errorText:
          identical(errorText, _unset) ? this.errorText : errorText as String?,
      joiningRoomId: identical(joiningRoomId, _unset)
          ? this.joiningRoomId
          : joiningRoomId as String?,
    );
  }
}

class JoinRoomController extends StateNotifier<JoinRoomState> {
  JoinRoomController(this._api) : super(JoinRoomState());

  final GameApi _api;

  void clearError() {
    state = state.copyWith(errorText: null);
  }

  Future<JoinLobbyResult> joinLobby(
    LobbyRoom room, {
    String? password,
  }) async {
    if (state.isLoading) {
      return JoinLobbyResult.failed;
    }

    if (room.requiresPassword) {
      final String safePassword = (password ?? '').trim();
      if (safePassword.isEmpty || safePassword != (room.password ?? '')) {
        state = state.copyWith(errorText: 'wrong_password');
        return JoinLobbyResult.invalidPassword;
      }
    }

    state = state.copyWith(
      isLoading: true,
      errorText: null,
      joiningRoomId: room.id,
    );

    try {
      await _api.joinRoom(room.code, playerName: 'You');
      return JoinLobbyResult.success;
    } catch (_) {
      state = state.copyWith(errorText: 'invalid');
      return JoinLobbyResult.failed;
    } finally {
      state = state.copyWith(
        isLoading: false,
        joiningRoomId: null,
      );
    }
  }
}

const List<LobbyRoom> _mockLobbies = <LobbyRoom>[
  LobbyRoom(
    id: 'room-1001',
    code: '1001',
    name: 'Friday Trivia Crew',
    currentPlayers: 3,
    maxPlayers: 4,
    type: LobbyType.multiplayer,
    requiresPassword: true,
    password: '4321',
  ),
  LobbyRoom(
    id: 'room-2034',
    code: '2034',
    name: 'Quick Duel Arena',
    currentPlayers: 1,
    maxPlayers: 2,
    type: LobbyType.duel,
    requiresPassword: false,
  ),
  LobbyRoom(
    id: 'room-8890',
    code: '8890',
    name: 'Movie Legends',
    currentPlayers: 2,
    maxPlayers: 4,
    type: LobbyType.multiplayer,
    requiresPassword: false,
  ),
  LobbyRoom(
    id: 'room-5562',
    code: '5562',
    name: 'Champions Duel',
    currentPlayers: 2,
    maxPlayers: 2,
    type: LobbyType.duel,
    requiresPassword: true,
    password: '7777',
  ),
];
