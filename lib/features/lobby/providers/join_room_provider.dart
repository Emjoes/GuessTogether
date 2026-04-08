import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/session/app_session_controller.dart';

const Object _unset = Object();

class JoinRoomState {
  JoinRoomState({
    this.rooms = const <RoomSummary>[],
    this.isLoading = false,
    this.isRefreshing = false,
    this.loadErrorText,
    this.joinErrorText,
    this.joiningRoomId,
  });

  final List<RoomSummary> rooms;
  final bool isLoading;
  final bool isRefreshing;
  final String? loadErrorText;
  final String? joinErrorText;
  final String? joiningRoomId;

  JoinRoomState copyWith({
    List<RoomSummary>? rooms,
    bool? isLoading,
    bool? isRefreshing,
    Object? loadErrorText = _unset,
    Object? joinErrorText = _unset,
    Object? joiningRoomId = _unset,
  }) {
    return JoinRoomState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      loadErrorText: identical(loadErrorText, _unset)
          ? this.loadErrorText
          : loadErrorText as String?,
      joinErrorText: identical(joinErrorText, _unset)
          ? this.joinErrorText
          : joinErrorText as String?,
      joiningRoomId: identical(joiningRoomId, _unset)
          ? this.joiningRoomId
          : joiningRoomId as String?,
    );
  }
}

class JoinRoomController extends StateNotifier<JoinRoomState> {
  JoinRoomController(this._api, [this._ref]) : super(JoinRoomState()) {
    unawaited(refreshRooms());
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => unawaited(refreshRooms()),
    );
  }

  final GameApi _api;
  final Ref? _ref;
  Timer? _refreshTimer;

  Future<void> refreshRooms() async {
    if (state.isRefreshing) {
      return;
    }
    state = state.copyWith(isRefreshing: true, loadErrorText: null);
    try {
      final List<RoomSummary> rooms = await _api.loadRooms();
      state = state.copyWith(rooms: rooms, loadErrorText: null);
    } catch (error) {
      state = state.copyWith(
        loadErrorText: error is Exception ? error.toString() : 'load_failed',
      );
    } finally {
      state = state.copyWith(isRefreshing: false);
    }
  }

  void clearError() {
    state = state.copyWith(joinErrorText: null);
  }

  Future<RoomSummary> joinLobby(
    RoomSummary room, {
    String? password,
  }) async {
    final String displayName = _ref
            ?.read(appSessionControllerProvider)
            .valueOrNull
            ?.session
            ?.displayName ??
        '';
    state = state.copyWith(
      isLoading: true,
      joinErrorText: null,
      joiningRoomId: room.id,
    );
    try {
      final RoomSummary joined = await _api.joinRoom(
        room.code,
        playerName: displayName,
        password: password,
      );
      await refreshRooms();
      return joined;
    } catch (error) {
      final String message = error.toString().toLowerCase();
      state = state.copyWith(
        joinErrorText:
            message.contains('password') ? 'wrong_password' : 'invalid',
      );
      rethrow;
    } finally {
      state = state.copyWith(
        isLoading: false,
        joiningRoomId: null,
      );
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final joinRoomControllerProvider =
    StateNotifierProvider.autoDispose<JoinRoomController, JoinRoomState>(
  (ref) => JoinRoomController(ref.read(gameApiProvider), ref),
);
