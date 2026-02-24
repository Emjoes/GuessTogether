import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/data/api/mock_http_adapter.dart';

enum RoomMode { multiplayer, duel }

extension RoomModeLabel on RoomMode {
  String get label {
    switch (this) {
      case RoomMode.multiplayer:
        return 'Multiplayer';
      case RoomMode.duel:
        return 'Duel';
    }
  }
}

final gameApiProvider = Provider<GameApi>((ref) {
  // Swap this for a real HTTP/Firebase adapter later.
  return MockHttpAdapter();
});

class CreateRoomState {
  CreateRoomState({
    this.name = '',
    this.password = '',
    this.mode = RoomMode.multiplayer,
    this.players = 4,
    this.isLoading = false,
  });

  final String name;
  final String password;
  final RoomMode mode;
  final int players;
  final bool isLoading;

  CreateRoomState copyWith({
    String? name,
    String? password,
    RoomMode? mode,
    int? players,
    bool? isLoading,
  }) {
    return CreateRoomState(
      name: name ?? this.name,
      password: password ?? this.password,
      mode: mode ?? this.mode,
      players: players ?? this.players,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CreateRoomController extends StateNotifier<CreateRoomState> {
  CreateRoomController(this._api) : super(CreateRoomState());

  final GameApi _api;

  void setName(String value) => state = state.copyWith(name: value);

  void setPassword(String value) => state = state.copyWith(password: value);

  void setMode(RoomMode value) {
    // Duel is always 2 players.
    final int nextPlayers = value == RoomMode.duel ? 2 : state.players;
    state = state.copyWith(mode: value, players: nextPlayers);
  }

  void setPlayers(int value) {
    final int safe = value.clamp(2, 4);
    state = state.copyWith(players: safe);
  }

  Future<void> createRoom() async {
    state = state.copyWith(isLoading: true);
    try {
      final request = CreateRoomRequest(
        name: state.name,
        mode: state.mode.name,
        topic: state.mode == RoomMode.duel ? 'Duel' : 'Multiplayer',
        rounds: 3,
        finalWagerEnabled: false,
      );
      await _api.createRoom(request);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final createRoomControllerProvider =
    StateNotifierProvider<CreateRoomController, CreateRoomState>(
  (ref) => CreateRoomController(ref.read(gameApiProvider)),
);
