import 'dart:async';

import 'package:guesstogether/data/api/realtime_adapter.dart';
import 'package:guesstogether/services/mock_match_host.dart';
import 'package:guesstogether/services/mock_ws_messages.dart';

/// Simple WebSocket-style adapter that exposes the [MockMatchHost] stream.
class MockWebSocketAdapter implements RealtimeAdapter {
  MockWebSocketAdapter(this._host);

  final MockMatchHost _host;

  @override
  Stream<WsMessage> get messages => _host.stream;

  @override
  Future<void> start() => _host.startScriptedMatch();
}
