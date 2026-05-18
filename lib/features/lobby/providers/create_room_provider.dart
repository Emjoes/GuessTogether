import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guesstogether/core/constants/question_packages.dart';
import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/session/app_session_controller.dart';

enum RoomMode { multiplayer, duel }

const String defaultRoomPackageFileName = standardQuestionPackFileName;

extension RoomModeLabel on RoomMode {
  String get label {
    switch (this) {
      case RoomMode.multiplayer:
        return 'Multiplayer';
      case RoomMode.duel:
        return 'Elimination';
    }
  }
}

class CreateRoomState {
  CreateRoomState({
    this.name = '',
    this.password = '',
    this.mode = RoomMode.multiplayer,
    this.packageFileName = defaultRoomPackageFileName,
    this.packageDisplayName = '',
    this.players = 4,
    this.isImportingPackage = false,
    this.isLoading = false,
  });

  final String name;
  final String password;
  final RoomMode mode;
  final String packageFileName;
  final String packageDisplayName;
  final int players;
  final bool isImportingPackage;
  final bool isLoading;

  bool get hasCustomPackage =>
      packageFileName.isNotEmpty &&
      packageFileName != defaultRoomPackageFileName &&
      packageDisplayName.trim().isNotEmpty;

  CreateRoomState copyWith({
    String? name,
    String? password,
    RoomMode? mode,
    String? packageFileName,
    String? packageDisplayName,
    int? players,
    bool? isImportingPackage,
    bool? isLoading,
  }) {
    return CreateRoomState(
      name: name ?? this.name,
      password: password ?? this.password,
      mode: mode ?? this.mode,
      packageFileName: packageFileName ?? this.packageFileName,
      packageDisplayName: packageDisplayName ?? this.packageDisplayName,
      players: players ?? this.players,
      isImportingPackage: isImportingPackage ?? this.isImportingPackage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CreateRoomController extends StateNotifier<CreateRoomState> {
  CreateRoomController(this._ref) : super(CreateRoomState());

  final Ref _ref;

  GameApi get _api => _ref.read(gameApiProvider);

  void reset() => state = CreateRoomState();

  void setName(String value) => state = state.copyWith(name: value);

  void setPassword(String value) => state = state.copyWith(password: value);

  void setPackageFileName(String value) =>
      state = state.copyWith(packageFileName: value);

  void setImportedPackage(ImportedPackageSummary package) {
    state = state.copyWith(
      packageFileName: package.packageFileName,
      packageDisplayName: package.packageName,
      isImportingPackage: false,
    );
  }

  void clearImportedPackage() {
    state = state.copyWith(
      packageFileName: defaultRoomPackageFileName,
      packageDisplayName: '',
      isImportingPackage: false,
    );
  }

  void setImportingPackage(bool value) {
    state = state.copyWith(isImportingPackage: value);
  }

  Future<ImportedPackageSummary> importSiqPackage({
    required String fileName,
    required Uint8List bytes,
  }) async {
    state = state.copyWith(isImportingPackage: true);
    try {
      final ImportedPackageSummary package = await _api.importSiqPackage(
        fileName: fileName,
        bytes: bytes,
      );
      setImportedPackage(package);
      return package;
    } finally {
      state = state.copyWith(isImportingPackage: false);
    }
  }

  void setMode(RoomMode value) {
    // Elimination mode is always 2 players.
    final int nextPlayers = value == RoomMode.duel ? 2 : state.players;
    state = state.copyWith(mode: value, players: nextPlayers);
  }

  void setPlayers(int value) {
    final int safe = value.clamp(2, 4);
    state = state.copyWith(players: safe);
  }

  Future<RoomSummary> createRoom() async {
    state = state.copyWith(isLoading: true);
    try {
      final request = CreateRoomRequest(
        name: state.name,
        password: state.password,
        mode: state.mode.name,
        topic: state.hasCustomPackage
            ? state.packageDisplayName
            : (state.mode == RoomMode.duel ? 'Elimination' : 'Multiplayer'),
        rounds: 3,
        finalWagerEnabled: false,
        maxPlayers: state.mode == RoomMode.duel ? 2 : state.players,
        packageFileName: state.packageFileName,
      );
      return await _api.createRoom(request);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final createRoomControllerProvider =
    StateNotifierProvider.autoDispose<CreateRoomController, CreateRoomState>(
  (ref) => CreateRoomController(ref),
);
