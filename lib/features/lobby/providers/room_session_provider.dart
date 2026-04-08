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
  bool _isDisposed = false;
  bool _isResyncing = false;

  Future<void> _disconnectRealtime() async {
    final StreamSubscription<RoomRealtimeMessage>? subscription = _subscription;
    final RoomRealtimeConnection? connection = _connection;
    _subscription = null;
    _connection = null;
    await subscription?.cancel();
    await connection?.close();
  }

  Future<void> _bootstrap() async {
    state = state.copyWith(isLoading: true, errorText: null);
    try {
      final RoomDetails room = await _api.loadRoom(roomId);
      if (_isDisposed) {
        return;
      }
      _ref.read(activeRoomProvider.notifier).state = room;
      state = state.copyWith(
        room: room,
        isLoading: false,
        hasStarted: room.summary.lifecycleStatus == RoomLifecycleStatus.inGame,
      );
      await _connect();
    } catch (_) {
      if (_isDisposed) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorText: 'load_failed',
      );
    }
  }

  Future<void> _connect() async {
    await _disconnectRealtime();
    if (_isDisposed) {
      return;
    }
    _connection = _api.connectToRoom(roomId);
    _subscription = _connection!.messages.listen(
      (RoomRealtimeMessage message) {
        if (_isDisposed) {
          return;
        }
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
        if (_isDisposed) {
          return;
        }
        state = state.copyWith(errorText: 'realtime_failed');
      },
    );
  }

  Future<void> resyncAfterResume() async {
    if (_isDisposed || _isResyncing) {
      return;
    }
    _isResyncing = true;
    try {
      final RoomDetails room = await _api.loadRoom(roomId);
      if (_isDisposed) {
        return;
      }
      _ref.read(activeRoomProvider.notifier).state = room;
      state = state.copyWith(
        room: room,
        isLoading: false,
        hasStarted: room.summary.lifecycleStatus == RoomLifecycleStatus.inGame,
        errorText: null,
      );
      if (room.summary.lifecycleStatus != RoomLifecycleStatus.finished) {
        await _connect();
      }
    } on BackendException catch (error) {
      if (_isDisposed) {
        return;
      }
      if (error.statusCode == 404 || error.statusCode == 403) {
        _ref.read(activeRoomProvider.notifier).state = null;
        state = state.copyWith(
          clearRoom: true,
          hasStarted: false,
          errorText: 'room_closed',
        );
      }
    } catch (_) {
      // Keep the last known state and let realtime recover on the next resume.
    } finally {
      _isResyncing = false;
    }
  }

  Future<void> handleAppDetached({required bool isHost}) async {
    if (isHost) {
      await leaveRoom();
      return;
    }
    await _disconnectRealtime();
  }

  Future<void> startRoom() async {
    state = state.copyWith(isStarting: true, errorText: null);
    try {
      await _api.startRoom(roomId);
    } on BackendException catch (error) {
      state = state.copyWith(
        errorText: error.message.isEmpty ? 'start_failed' : error.message,
      );
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
      await _disconnectRealtime();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_disconnectRealtime());
    super.dispose();
  }
}

final waitingRoomControllerProvider = StateNotifierProvider.autoDispose
    .family<WaitingRoomController, WaitingRoomState, String>(
  (ref, String roomId) =>
      WaitingRoomController(ref, ref.read(appBackendApiProvider), roomId),
);
