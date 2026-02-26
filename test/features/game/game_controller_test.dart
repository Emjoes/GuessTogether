import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:guesstogether/data/api/realtime_adapter.dart';
import 'package:guesstogether/features/game/domain/game_models.dart';
import 'package:guesstogether/features/game/providers/game_providers.dart';
import 'package:guesstogether/services/mock_ws_messages.dart';

class _TestRealtimeAdapter implements RealtimeAdapter {
  final StreamController<WsMessage> controller =
      StreamController<WsMessage>.broadcast();

  @override
  Stream<WsMessage> get messages => controller.stream;

  @override
  Future<void> start() async {}

  Future<void> dispose() async => controller.close();
}

void main() {
  test('GameController updates players on room_update', () async {
    final adapter = _TestRealtimeAdapter();
    final c = GameController(adapter);

    adapter.controller.add(
      RoomUpdateMessage(
        players: <WsPlayer>[
          WsPlayer(id: 'p1', name: 'You', score: 10),
          WsPlayer(id: 'p2', name: 'Bot', score: 20),
        ],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(c.state.players.length, 2);
    expect(
        c.state.players.first, const Player(id: 'p1', name: 'You', score: 10));

    c.dispose();
    await adapter.dispose();
  });

  test('GameController sets match ended on match_end', () async {
    final adapter = _TestRealtimeAdapter();
    final c = GameController(adapter);

    adapter.controller.add(MatchEndMessage(winnerId: 'p1'));
    await Future<void>.delayed(Duration.zero);

    expect(c.state.isMatchEnded, true);
    expect(c.state.winnerId, 'p1');

    c.dispose();
    await adapter.dispose();
  });
}
