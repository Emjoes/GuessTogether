import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/data/api/mock_http_adapter.dart';

final joinRoomControllerProvider =
    StateNotifierProvider<JoinRoomController, JoinRoomState>(
  (ref) => JoinRoomController(MockHttpAdapter()),
);

class JoinRoomState {
  JoinRoomState({
    this.code = '',
    this.isLoading = false,
    this.errorText,
    List<String>? recentCodes,
  }) : recentCodes = recentCodes ?? <String>['1234', '5678', '9999'];

  final String code;
  final bool isLoading;
  final String? errorText;
  final List<String> recentCodes;

  JoinRoomState copyWith({
    String? code,
    bool? isLoading,
    String? errorText,
    List<String>? recentCodes,
  }) {
    return JoinRoomState(
      code: code ?? this.code,
      isLoading: isLoading ?? this.isLoading,
      errorText: errorText,
      recentCodes: recentCodes ?? this.recentCodes,
    );
  }
}

class JoinRoomController extends StateNotifier<JoinRoomState> {
  JoinRoomController(this._api) : super(JoinRoomState());

  final GameApi _api;

  void setCode(String code) {
    state = state.copyWith(code: code, errorText: null);
  }

  Future<void> submit() async {
    state = state.copyWith(isLoading: true, errorText: null);
    try {
      await _api.joinRoom(state.code, playerName: 'You');
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorText: 'invalid',
      );
      return;
    }
    state = state.copyWith(isLoading: false);
  }

  void useRecent(String code) {
    setCode(code);
  }
}
