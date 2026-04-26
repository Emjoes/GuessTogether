import 'package:equatable/equatable.dart';

import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/game/domain/game_models.dart';

class AuthSession extends Equatable {
  const AuthSession({
    required this.playerId,
    required this.sessionToken,
    required this.displayName,
    required this.email,
  });

  final String playerId;
  final String sessionToken;
  final String displayName;
  final String email;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'playerId': playerId,
        'sessionToken': sessionToken,
        'displayName': displayName,
        'email': email,
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      playerId: json['playerId'] as String? ?? '',
      sessionToken: json['sessionToken'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[playerId, sessionToken, displayName, email];
}

class UserSettingsDto extends Equatable {
  const UserSettingsDto({
    required this.themeMode,
    required this.languageCode,
  });

  static const UserSettingsDto defaults = UserSettingsDto(
    themeMode: '',
    languageCode: '',
  );

  final String themeMode;
  final String languageCode;

  UserSettingsDto copyWith({
    String? themeMode,
    String? languageCode,
  }) {
    return UserSettingsDto(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'themeMode': themeMode,
        'languageCode': languageCode,
      };

  factory UserSettingsDto.fromJson(Map<String, dynamic> json) {
    return UserSettingsDto(
      themeMode: json['themeMode'] as String? ?? '',
      languageCode: json['languageCode'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[themeMode, languageCode];
}

class AppVersionStatus extends Equatable {
  const AppVersionStatus({
    required this.latestVersion,
    required this.minimumSupportedVersion,
  });

  final String latestVersion;
  final String minimumSupportedVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'latestVersion': latestVersion,
        'minimumSupportedVersion': minimumSupportedVersion,
      };

  factory AppVersionStatus.fromJson(Map<String, dynamic> json) {
    return AppVersionStatus(
      latestVersion: json['latestVersion'] as String? ?? '',
      minimumSupportedVersion: json['minimumSupportedVersion'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[latestVersion, minimumSupportedVersion];
}

class BootstrapPayload extends Equatable {
  const BootstrapPayload({
    required this.session,
    required this.profile,
    required this.settings,
  });

  final AuthSession session;
  final ProfileSummary profile;
  final UserSettingsDto settings;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'session': session.toJson(),
        'profile': profile.toJson(),
        'settings': settings.toJson(),
      };

  factory BootstrapPayload.fromJson(Map<String, dynamic> json) {
    return BootstrapPayload(
      session: AuthSession.fromJson(json['session'] as Map<String, dynamic>),
      profile: ProfileSummary.fromJson(json['profile'] as Map<String, dynamic>),
      settings:
          UserSettingsDto.fromJson(json['settings'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => <Object?>[session, profile, settings];
}

class RegisterRequest extends Equatable {
  const RegisterRequest({
    required this.displayName,
    required this.password,
  });

  final String displayName;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'displayName': displayName,
        'password': password,
      };

  @override
  List<Object?> get props => <Object?>[displayName, password];
}

class LoginRequest extends Equatable {
  const LoginRequest({
    required this.credential,
    required this.password,
  });

  final String credential;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'credential': credential,
        'password': password,
      };

  @override
  List<Object?> get props => <Object?>[credential, password];
}

class RoomRealtimeMessage extends Equatable {
  const RoomRealtimeMessage({
    required this.type,
    required this.room,
    this.gameState,
  });

  final String type;
  final RoomDetails room;
  final GameState? gameState;

  factory RoomRealtimeMessage.fromJson(Map<String, dynamic> json) {
    return RoomRealtimeMessage(
      type: json['type'] as String? ?? 'room_state',
      room: RoomDetails.fromJson(json['room'] as Map<String, dynamic>),
      gameState: json['gameState'] is Map<String, dynamic>
          ? GameState.fromJson(json['gameState'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'room': room.toJson(),
        'gameState': gameState?.toJson(),
      };

  bool get isStarted => type == 'room_started';
  bool get isClosed => type == 'room_closed';

  @override
  List<Object?> get props => <Object?>[type, room, gameState];
}
