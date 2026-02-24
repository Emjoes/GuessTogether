import 'package:guesstogether/services/mock_ws_messages.dart';

/// Realtime adapter abstraction (e.g. WebSocket, Firebase realtime, etc).
abstract class RealtimeAdapter {
  Stream<WsMessage> get messages;
  Future<void> start();
}
