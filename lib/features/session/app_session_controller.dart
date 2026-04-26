import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:guesstogether/core/l10n/app_locale.dart';
import 'package:guesstogether/core/theme/app_theme.dart';
import 'package:guesstogether/data/api/app_backend_api.dart';
import 'package:guesstogether/data/api/backend_models.dart';
import 'package:guesstogether/data/api/game_api.dart';

final backendBaseHttpUrlProvider = Provider<String>((ref) {
  const String defined = String.fromEnvironment('API_BASE_URL');
  if (defined.isNotEmpty) {
    return defined;
  }
  if (kReleaseMode) {
    return 'https://guess-together.gall-studio.com';
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://127.0.0.1:8080';
});

final backendBaseWsUrlProvider = Provider<String>((ref) {
  final String httpUrl = ref.watch(backendBaseHttpUrlProvider);
  if (httpUrl.startsWith('https://')) {
    return httpUrl.replaceFirst('https://', 'wss://');
  }
  if (httpUrl.startsWith('http://')) {
    return httpUrl.replaceFirst('http://', 'ws://');
  }
  return httpUrl;
});

final appSessionControllerProvider =
    AsyncNotifierProvider<AppSessionController, AppSessionState>(
  AppSessionController.new,
);

final appBackendApiProvider = Provider<AppBackendApi>((ref) {
  final String baseHttpUrl = ref.watch(backendBaseHttpUrlProvider);
  final String baseWsUrl = ref.watch(backendBaseWsUrlProvider);
  final String? sessionToken = ref
      .watch(appSessionControllerProvider)
      .valueOrNull
      ?.session
      ?.sessionToken;
  return HttpAppBackendApi(
    baseHttpUrl: baseHttpUrl,
    baseWsUrl: baseWsUrl,
    sessionToken: sessionToken,
  );
});

final gameApiProvider = Provider<GameApi>((ref) {
  return ref.watch(appBackendApiProvider);
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(appSessionControllerProvider).valueOrNull?.themeMode ??
      defaultThemeModeFromSystem();
});

final appLanguageProvider = Provider<AppLanguage>((ref) {
  return ref.watch(appSessionControllerProvider).valueOrNull?.appLanguage ??
      defaultAppLanguageFromSystem();
});

class AppSessionState {
  const AppSessionState({
    required this.session,
    required this.profile,
    required this.themeMode,
    required this.appLanguage,
  });

  final AuthSession? session;
  final ProfileSummary? profile;
  final ThemeMode themeMode;
  final AppLanguage appLanguage;

  bool get isAuthenticated => session != null;

  AppSessionState copyWith({
    AuthSession? session,
    bool clearSession = false,
    ProfileSummary? profile,
    bool clearProfile = false,
    ThemeMode? themeMode,
    AppLanguage? appLanguage,
  }) {
    return AppSessionState(
      session: clearSession ? null : (session ?? this.session),
      profile: clearProfile ? null : (profile ?? this.profile),
      themeMode: themeMode ?? this.themeMode,
      appLanguage: appLanguage ?? this.appLanguage,
    );
  }
}

class AppSessionController extends AsyncNotifier<AppSessionState> {
  static const String _sessionKey = 'app.session';
  static const String _profileKey = 'app.profile';
  static const String _themeModeKey = 'app.theme_mode';
  static const String _languageKey = 'app.language';

  HttpAppBackendApi _client({String? sessionToken}) {
    final String baseHttpUrl = ref.read(backendBaseHttpUrlProvider);
    final String baseWsUrl = ref.read(backendBaseWsUrlProvider);
    return HttpAppBackendApi(
      baseHttpUrl: baseHttpUrl,
      baseWsUrl: baseWsUrl,
      sessionToken: sessionToken,
    );
  }

  AppSessionState _fallbackState() {
    return AppSessionState(
      session: null,
      profile: null,
      themeMode: defaultThemeModeFromSystem(),
      appLanguage: defaultAppLanguageFromSystem(),
    );
  }

  @override
  Future<AppSessionState> build() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final ThemeMode themeMode =
        _themeModeFromStorage(preferences.getString(_themeModeKey)) ??
            defaultThemeModeFromSystem();
    final AppLanguage appLanguage =
        _languageFromStorage(preferences.getString(_languageKey)) ??
            defaultAppLanguageFromSystem();
    final AuthSession? storedSession =
        _sessionFromStorage(preferences.getString(_sessionKey));
    final ProfileSummary? storedProfile =
        _profileFromStorage(preferences.getString(_profileKey));

    final AppSessionState restored = AppSessionState(
      session: storedSession,
      profile: storedProfile,
      themeMode: themeMode,
      appLanguage: appLanguage,
    );
    if (storedSession == null) {
      return restored;
    }

    try {
      final BootstrapPayload payload = await _client(
        sessionToken: storedSession.sessionToken,
      ).loadBootstrap();
      final AppSessionState next = restored.copyWith(
        session: payload.session,
        profile: payload.profile,
        themeMode: _themeModeFromStorage(payload.settings.themeMode) ??
            restored.themeMode,
        appLanguage: _languageFromStorage(payload.settings.languageCode) ??
            restored.appLanguage,
      );
      await _persist(preferences, next);
      return next;
    } on BackendException catch (error) {
      if (error.statusCode == 401) {
        final AppSessionState cleared = restored.copyWith(
          clearSession: true,
          clearProfile: true,
        );
        await _persist(preferences, cleared);
        return cleared;
      }
      return restored;
    } catch (_) {
      return restored;
    }
  }

  Future<void> register({
    required String displayName,
    required String password,
  }) async {
    final String safeName = displayName.trim();
    final String safePassword = password;
    if (safeName.isEmpty || safePassword.isEmpty) {
      throw const BackendException('All fields are required');
    }

    final AppSessionState current = state.valueOrNull ?? _fallbackState();

    state = const AsyncLoading<AppSessionState>().copyWithPrevious(state);
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final BootstrapPayload payload = await _client().register(
        RegisterRequest(
          displayName: safeName,
          password: safePassword,
        ),
      );
      final AppSessionState next = current.copyWith(
        session: payload.session,
        profile: payload.profile,
        themeMode: _themeModeFromStorage(payload.settings.themeMode) ??
            current.themeMode,
        appLanguage: _languageFromStorage(payload.settings.languageCode) ??
            current.appLanguage,
      );
      await _persist(preferences, next);
      state = AsyncValue.data(next);
    } catch (_) {
      state = AsyncValue.data(current);
      rethrow;
    }
  }

  Future<void> login({
    required String credential,
    required String password,
  }) async {
    final String safeCredential = credential.trim();
    final String safePassword = password;
    if (safeCredential.isEmpty || safePassword.isEmpty) {
      throw const BackendException('Nickname and password are required');
    }

    final AppSessionState current = state.valueOrNull ?? _fallbackState();
    state = const AsyncLoading<AppSessionState>().copyWithPrevious(state);
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final BootstrapPayload payload = await _client().login(
        LoginRequest(
          credential: safeCredential,
          password: safePassword,
        ),
      );
      final AppSessionState next = current.copyWith(
        session: payload.session,
        profile: payload.profile,
        themeMode: _themeModeFromStorage(payload.settings.themeMode) ??
            current.themeMode,
        appLanguage: _languageFromStorage(payload.settings.languageCode) ??
            current.appLanguage,
      );
      await _persist(preferences, next);
      state = AsyncValue.data(next);
    } catch (_) {
      state = AsyncValue.data(current);
      rethrow;
    }
  }

  Future<void> logout() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final AppSessionState next = AppSessionState(
      session: null,
      profile: null,
      themeMode: state.valueOrNull?.themeMode ?? defaultThemeModeFromSystem(),
      appLanguage:
          state.valueOrNull?.appLanguage ?? defaultAppLanguageFromSystem(),
    );
    state = AsyncValue.data(next);
    await _persist(preferences, next);
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    final AppSessionState current = state.valueOrNull ?? _fallbackState();
    final AppSessionState next = current.copyWith(themeMode: themeMode);
    state = AsyncValue.data(next);
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await _persist(preferences, next);
    await _trySyncSettings(next);
  }

  Future<void> updateLanguage(AppLanguage appLanguage) async {
    final AppSessionState current = state.valueOrNull ?? _fallbackState();
    final AppSessionState next = current.copyWith(appLanguage: appLanguage);
    state = AsyncValue.data(next);
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await _persist(preferences, next);
    await _trySyncSettings(next);
  }

  Future<void> _trySyncSettings(AppSessionState stateValue) async {
    final AuthSession? session = stateValue.session;
    if (session == null) {
      return;
    }
    try {
      await _client(sessionToken: session.sessionToken).saveSettings(
        UserSettingsDto(
          themeMode: _themeModeToStorage(stateValue.themeMode),
          languageCode: _languageToStorage(stateValue.appLanguage),
        ),
      );
    } catch (_) {
      // Local persistence already succeeded. We keep the UI responsive and
      // retry on the next successful bootstrap.
    }
  }

  Future<void> _persist(
    SharedPreferences preferences,
    AppSessionState state,
  ) async {
    if (state.session == null) {
      await preferences.remove(_sessionKey);
    } else {
      await preferences.setString(
        _sessionKey,
        jsonEncode(state.session!.toJson()),
      );
    }
    if (state.profile == null) {
      await preferences.remove(_profileKey);
    } else {
      await preferences.setString(
        _profileKey,
        jsonEncode(state.profile!.toJson()),
      );
    }
    await preferences.setString(
        _themeModeKey, _themeModeToStorage(state.themeMode));
    await preferences.setString(
      _languageKey,
      _languageToStorage(state.appLanguage),
    );
  }

  AuthSession? _sessionFromStorage(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AuthSession.fromJson(decoded);
      }
    } catch (_) {
      // Ignore malformed local cache and continue with a clean session.
    }
    return null;
  }

  ProfileSummary? _profileFromStorage(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return ProfileSummary.fromJson(decoded);
      }
    } catch (_) {
      // Ignore malformed local cache and continue without a cached profile.
    }
    return null;
  }

  ThemeMode? _themeModeFromStorage(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return null;
    }
  }

  String _themeModeToStorage(ThemeMode value) {
    switch (value) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
      case ThemeMode.system:
        return 'light';
    }
  }

  AppLanguage? _languageFromStorage(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'ru':
      case 'russian':
        return AppLanguage.russian;
      case 'en':
      case 'english':
        return AppLanguage.english;
      default:
        return null;
    }
  }

  String _languageToStorage(AppLanguage value) {
    switch (value) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.russian:
        return 'ru';
    }
  }
}
