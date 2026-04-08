import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guesstogether/data/api/app_backend_api.dart';
import 'package:guesstogether/data/api/backend_models.dart';
import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/session/app_session_controller.dart';

const Object _waitingUnset = Object();

final activeRoomProvider = StateProvider<RoomDetails?>((ref) => null);

class WaitingRoomState {
  const WaitingRoomState({
    this.room,
    this.isLoading = true,
    this.isStarting = false,
    this.hasStarted = false,
    this.errorText,
  });

  final RoomDetails? room;
  final bool isLoading;
  final bool isStarting;
  final bool hasStarted;
  final String? errorText;

  WaitingRoomState copyWith({
    RoomDetails? room,
    bool clearRoom = false,
    bool? isLoading,
    bool? isStarting,
    bool? hasStarted,
    Object? errorText = _waitingUnset,
  }) {
    return WaitingRoomState(
      room: clearRoom ? null : (room ?? this.room),
      isLoading: isLoading ?? this.isLoading,
      isStarting: isStarting ?? this.isStarting,
      hasStarted: hasStarted ?? this.hasStarted,
      errorText: identical(errorText, _waitingUnset)
          ? this.errorText
          : errorText as String?,
    );
  }
}

class WaitingRoomController extends StateNotifier<WaitingRoomState> {
  WaitingRoomController(
    this._ref,
    this._api,
    this.roomId,
  ) : super(const WaitingRoomState()) {
    unawaited(_bootstrap());
  }

  final Ref _ref;
  final AppBackendApi _api;
  final String roomId;

  StreamSubscription<RoomRealtimeMessage>? _subscription;
  RoomRealtimeConnection? _connection;

  Future<void> _bootstrap() async {
    state = state.copyWith(isLoading: true, errorText: null);
    try {
      final RoomDetails room = await _api.loadRoom(roomId);
      _ref.read(activeRoomProvider.notifier).state = room;
      state = state.copyWith(
        room: room,
        isLoading: false,
        hasStarted: room.summary.lifecycleStatus == RoomLifecycleStatus.inGame,
      );
      await _connect();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorText: 'load_failed',
      );
    }
  }

  Future<void> _connect() async {
    _connection = _api.connectToRoom(roomId);
    _subscription = _connection!.messages.listen(
      (RoomRealtimeMessage message) {
        if (message.isClosed) {
          _ref.read(activeRoomProvider.notifier).state = null;
          state = state.copyWith(
            clearRoom: true,
            hasStarted: false,
            errorText: 'room_closed',
          );
          return;
        }
        _ref.read(activeRoomProvider.notifier).state = message.room;
        state = state.copyWith(
          room: message.room,
          hasStarted: message.isStarted ||
              message.room.summary.lifecycleStatus ==
                  RoomLifecycleStatus.inGame,
          errorText: null,
        );
      },
      onError: (_) {
        state = state.copyWith(errorText: 'realtime_failed');
      },
    );
  }

  Future<void> startRoom() async {
    state = state.copyWith(isStarting: true, errorText: null);
    try {
      await _api.startRoom(roomId);
    } catch (_) {
      state = state.copyWith(errorText: 'start_failed');
    } finally {
      state = state.copyWith(isStarting: false);
    }
  }

  Future<void> leaveRoom() async {
    try {
      await _api.leaveRoom(roomId);
    } finally {
      _ref.read(activeRoomProvider.notifier).state = null;
      await _subscription?.cancel();
      await _connection?.close();
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_connection?.close());
    super.dispose();
  }
}

final waitingRoomControllerProvider = StateNotifierProvider.autoDispose
    .family<WaitingRoomController, WaitingRoomState, String>(
  (ref, String roomId) =>
      WaitingRoomController(ref, ref.read(appBackendApiProvider), roomId),
);
