import 'package:flutter_test/flutter_test.dart';
import 'package:guesstogether/data/api/backend_models.dart';

import '../../bin/server.dart';

void main() {
  test('StoredUser reconciles hosted matches into games played', () {
    final StoredUser user = StoredUser(
      id: 'host-1',
      sessionToken: 'session',
      email: 'host@example.com',
      displayName: 'Host',
      passwordHash: 'hashed',
      gamesPlayed: 0,
      winRate: 0,
      bestScore: 0,
      wins: 0,
      losses: 0,
      totalXp: 0,
      clutchCorrectAnswers: 0,
      unlockedAchievementIds: <String>[],
      recentMatches: <StoredRecentMatch>[
        StoredRecentMatch(
          roomName: 'Match 1',
          won: false,
          mode: 'multiplayer',
          playedAtEpochMs: 1,
          wasHost: true,
        ),
        StoredRecentMatch(
          roomName: 'Match 2',
          won: false,
          mode: 'multiplayer',
          playedAtEpochMs: 2,
          wasHost: true,
        ),
      ],
      settings: UserSettingsDto.defaults,
    );

    user.reconcileProfileStatsFromHistory();

    expect(user.gamesPlayed, 2);
    expect(user.losses, 0);
  });
}
