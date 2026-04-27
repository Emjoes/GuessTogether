import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:guesstogether/data/api/backend_models.dart';
import 'package:guesstogether/data/api/game_api.dart';

abstract class AppBackendApi implements GameApi {
  Future<AppVersionStatus> loadAppVersionStatus();
  Future<BootstrapPayload> register(RegisterRequest request);
  Future<BootstrapPayload> login(LoginRequest request);
  Future<BootstrapPayload> loadBootstrap();
  Future<void> saveSettings(UserSettingsDto settings);
  Future<void> chooseQuestion(String roomId, String questionId);
  Future<void> requestAnswer(String roomId);
  Future<void> passQuestion(String roomId);
  Future<void> acceptAnswer(String roomId);
  Future<void> rejectAnswer(String roomId);
  Future<void> togglePause(String roomId);
  Future<void> skipQuestion(String roomId);
  Future<void> skipRound(String roomId);
  Future<void> setPlayerScore(String roomId, String playerId, int score);
  RoomRealtimeConnection connectToRoom(String roomId);
}

class BackendException implements Exception {
  const BackendException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return 'BackendException($message)';
    }
    return 'BackendException($statusCode, $message)';
  }
}

class RoomRealtimeConnection {
  RoomRealtimeConnection({
    required this.messages,
    required Future<void> Function() onClose,
  }) : _onClose = onClose;

  final Stream<RoomRealtimeMessage> messages;
  final Future<void> Function() _onClose;

  Future<void> close() => _onClose();
}

class HttpAppBackendApi implements AppBackendApi {
  HttpAppBackendApi({
    required this.baseHttpUrl,
    required this.baseWsUrl,
    this.sessionToken,
    this.languageCode = '',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseHttpUrl;
  final String baseWsUrl;
  final String? sessionToken;
  final String languageCode;
  final http.Client _httpClient;

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final String normalizedBase = baseHttpUrl.endsWith('/')
        ? baseHttpUrl.substring(0, baseHttpUrl.length - 1)
        : baseHttpUrl;
    return Uri.parse('$normalizedBase$path').replace(
      queryParameters: queryParameters,
    );
  }

  Map<String, String> _headers({bool includeAuth = true}) {
    return <String, String>{
      'content-type': 'application/json',
      if (languageCode.trim().isNotEmpty) 'x-language-code': languageCode,
      if (includeAuth && sessionToken != null && sessionToken!.isNotEmpty)
        'authorization': 'Bearer $sessionToken',
    };
  }

  Future<Map<String, dynamic>> _decodeObject(http.Response response) async {
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const BackendException('Invalid server response');
    }
    return decoded;
  }

  Future<List<dynamic>> _decodeList(http.Response response) async {
    if (response.body.isEmpty) {
      return <dynamic>[];
    }
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) {
      throw const BackendException('Invalid server response');
    }
    return decoded;
  }

  Future<void> _ensureSuccess(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    String message = 'Request failed';
    try {
      final Map<String, dynamic> body = await _decodeObject(response);
      message = body['error'] as String? ?? message;
    } catch (_) {
      if (response.body.isNotEmpty) {
        message = response.body;
      }
    }
    throw BackendException(message, statusCode: response.statusCode);
  }

  @override
  Future<AppVersionStatus> loadAppVersionStatus() async {
    final http.Response response = await _httpClient.get(
      _uri('/api/app-version'),
      headers: _headers(includeAuth: false),
    );
    await _ensureSuccess(response);
    return AppVersionStatus.fromJson(await _decodeObject(response));
  }

  @override
  Future<BootstrapPayload> register(RegisterRequest request) async {
    final http.Response response = await _httpClient.post(
      _uri('/api/register'),
      headers: _headers(includeAuth: false),
      body: jsonEncode(request.toJson()),
    );
    await _ensureSuccess(response);
    return BootstrapPayload.fromJson(await _decodeObject(response));
  }

  @override
  Future<BootstrapPayload> login(LoginRequest request) async {
    final http.Response response = await _httpClient.post(
      _uri('/api/login'),
      headers: _headers(includeAuth: false),
      body: jsonEncode(request.toJson()),
    );
    await _ensureSuccess(response);
    return BootstrapPayload.fromJson(await _decodeObject(response));
  }

  @override
  Future<BootstrapPayload> loadBootstrap() async {
    final http.Response response = await _httpClient.get(
      _uri('/api/me'),
      headers: _headers(),
    );
    await _ensureSuccess(response);
    return BootstrapPayload.fromJson(await _decodeObject(response));
  }

  @override
  Future<void> saveSettings(UserSettingsDto settings) async {
    final http.Response response = await _httpClient.put(
      _uri('/api/me/settings'),
      headers: _headers(),
      body: jsonEncode(settings.toJson()),
    );
    await _ensureSuccess(response);
  }

  @override
  Future<RoomSummary> createRoom(CreateRoomRequest request) async {
    final http.Response response = await _httpClient.post(
      _uri('/api/rooms'),
      headers: _headers(),
      body: jsonEncode(request.toJson()),
    );
    await _ensureSuccess(response);
    return RoomSummary.fromJson(await _decodeObject(response));
  }

  @override
  Future<RoomSummary> joinRoom(
    String code, {
    required String playerName,
    String? password,
  }) async {
    final http.Response response = await _httpClient.post(
      _uri('/api/rooms/join'),
      headers: _headers(),
      body: jsonEncode(
        <String, dynamic>{
          'code': code,
          'playerName': playerName,
          'password': password ?? '',
        },
      ),
    );
    await _ensureSuccess(response);
    return RoomSummary.fromJson(await _decodeObject(response));
  }

  @override
  Future<List<RoomSummary>> loadRooms() async {
    final http.Response response = await _httpClient.get(
      _uri('/api/rooms'),
      headers: _headers(),
    );
    await _ensureSuccess(response);
    final List<dynamic> decoded = await _decodeList(response);
    return decoded
        .map((dynamic item) =>
            RoomSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<RoomDetails> loadRoom(String roomId) async {
    final http.Response response = await _httpClient.get(
      _uri('/api/rooms/$roomId'),
      headers: _headers(),
    );
    await _ensureSuccess(response);
    return RoomDetails.fromJson(await _decodeObject(response));
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    final http.Response response = await _httpClient.post(
      _uri('/api/rooms/$roomId/leave'),
      headers: _headers(),
    );
    await _ensureSuccess(response);
  }

  @override
  Future<void> startRoom(String roomId) async {
    final http.Response response = await _httpClient.post(
      _uri('/api/rooms/$roomId/start'),
      headers: _headers(),
    );
    await _ensureSuccess(response);
  }

  Future<void> _postGameAction(
    String roomId,
    String action, {
    Map<String, dynamic>? payload,
  }) async {
    final http.Response response = await _httpClient.post(
      _uri('/api/rooms/$roomId/game/$action'),
      headers: _headers(),
      body: jsonEncode(payload ?? <String, dynamic>{}),
    );
    await _ensureSuccess(response);
  }

  @override
  Future<void> chooseQuestion(String roomId, String questionId) {
    return _postGameAction(
      roomId,
      'choose',
      payload: <String, dynamic>{'questionId': questionId},
    );
  }

  @override
  Future<void> requestAnswer(String roomId) {
    return _postGameAction(roomId, 'answer');
  }

  @override
  Future<void> passQuestion(String roomId) {
    return _postGameAction(roomId, 'pass');
  }

  @override
  Future<void> acceptAnswer(String roomId) {
    return _postGameAction(roomId, 'accept');
  }

  @override
  Future<void> rejectAnswer(String roomId) {
    return _postGameAction(roomId, 'reject');
  }

  @override
  Future<void> togglePause(String roomId) {
    return _postGameAction(roomId, 'pause');
  }

  @override
  Future<void> skipQuestion(String roomId) {
    return _postGameAction(roomId, 'skip');
  }

  @override
  Future<void> skipRound(String roomId) {
    return _postGameAction(roomId, 'skip-round');
  }

  @override
  Future<void> setPlayerScore(String roomId, String playerId, int score) {
    return _postGameAction(
      roomId,
      'score',
      payload: <String, dynamic>{
        'playerId': playerId,
        'score': score,
      },
    );
  }

  @override
  Future<ProfileSummary> loadProfile() async {
    final BootstrapPayload payload = await loadBootstrap();
    return payload.profile;
  }

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard(LeaderboardScope scope) async {
    final http.Response response = await _httpClient.get(
      _uri('/api/leaderboard', <String, String>{'scope': scope.name}),
      headers: _headers(),
    );
    await _ensureSuccess(response);
    final List<dynamic> decoded = await _decodeList(response);
    return decoded
        .map(
          (dynamic item) =>
              LeaderboardEntry.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  RoomRealtimeConnection connectToRoom(String roomId) {
    final String normalizedBase = baseWsUrl.endsWith('/')
        ? baseWsUrl.substring(0, baseWsUrl.length - 1)
        : baseWsUrl;
    final Uri uri = Uri.parse('$normalizedBase/ws/rooms/$roomId').replace(
      queryParameters: <String, String>{
        if (sessionToken != null && sessionToken!.isNotEmpty)
          'token': sessionToken!,
        if (languageCode.trim().isNotEmpty) 'languageCode': languageCode,
      },
    );
    final WebSocketChannel channel = WebSocketChannel.connect(uri);
    final Stream<RoomRealtimeMessage> stream = channel.stream.map(
      (dynamic event) {
        final Map<String, dynamic> json =
            jsonDecode(event as String) as Map<String, dynamic>;
        return RoomRealtimeMessage.fromJson(json);
      },
    );
    return RoomRealtimeConnection(
      messages: stream,
      onClose: () async {
        await channel.sink.close();
      },
    );
  }
}
