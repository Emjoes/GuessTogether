import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/data/api/mock_http_adapter.dart';

enum RoomMode { realtime, bots, duel, custom }

extension RoomModeLabel on RoomMode {
  String get label {
    switch (this) {
      case RoomMode.realtime:
        return 'Realtime 2-4';
      case RoomMode.bots:
        return 'Bots';
      case RoomMode.duel:
        return 'Duel';
      case RoomMode.custom:
        return 'Custom';
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
    this.topic = '',
    this.mode = RoomMode.realtime,
    this.rounds = 3,
    this.finalWagerEnabled = true,
    this.minPlayers = 2,
    this.maxPlayers = 4,
    this.isLoading = false,
  });

  final String name;
  final String topic;
  final RoomMode mode;
  final int rounds;
  final bool finalWagerEnabled;
  final int minPlayers;
  final int maxPlayers;
  final bool isLoading;

  CreateRoomState copyWith({
    String? name,
    String? topic,
    RoomMode? mode,
    int? rounds,
    bool? finalWagerEnabled,
    int? minPlayers,
    int? maxPlayers,
    bool? isLoading,
  }) {
    return CreateRoomState(
      name: name ?? this.name,
      topic: topic ?? this.topic,
      mode: mode ?? this.mode,
      rounds: rounds ?? this.rounds,
      finalWagerEnabled: finalWagerEnabled ?? this.finalWagerEnabled,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CreateRoomController extends StateNotifier<CreateRoomState> {
  CreateRoomController(this._api) : super(CreateRoomState());

  final GameApi _api;

  void setName(String value) => state = state.copyWith(name: value);

  void setTopic(String value) => state = state.copyWith(topic: value);

  void setMode(RoomMode value) => state = state.copyWith(mode: value);

  void setRounds(int value) {
    final safe = value.clamp(1, 10);
    state = state.copyWith(rounds: safe);
  }

  void setFinalWager(bool value) =>
      state = state.copyWith(finalWagerEnabled: value);

  Future<void> createRoom() async {
    state = state.copyWith(isLoading: true);
    try {
      final request = CreateRoomRequest(
        name: state.name,
        mode: state.mode.name,
        topic: state.topic,
        rounds: state.rounds,
        finalWagerEnabled: state.finalWagerEnabled,
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
