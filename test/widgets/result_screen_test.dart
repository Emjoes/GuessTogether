import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:guesstogether/features/game/domain/game_models.dart';
import 'package:guesstogether/features/game/providers/game_providers.dart';
import 'package:guesstogether/features/home/presentation/home_screen.dart';
import 'package:guesstogether/features/result/presentation/result_screen.dart';
import '../test_app.dart';

class _FakeGameController extends GameController {
  _FakeGameController() : super(enableLocalTimers: false) {
    state = GameState.initial().copyWith(
      players: const <Player>[
        Player(id: 'p1', name: 'You', score: 100),
        Player(id: 'p2', name: 'Bot', score: 50),
      ],
      phase: GamePhase.finished,
      isMatchEnded: true,
    );
  }
}

class _MutableResultGameController extends GameController {
  _MutableResultGameController(GameState initialState)
      : super(enableLocalTimers: false) {
    state = initialState;
  }

  void replaceState(GameState next) {
    state = next;
  }
}

void main() {
  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: ResultScreen.routePath,
      routes: <RouteBase>[
        GoRoute(
          path: HomeScreen.routePath,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: ResultScreen.routePath,
          builder: (context, state) => const ResultScreen(),
        ),
      ],
    );
  }

  testWidgets('ResultScreen back button navigates to home', (tester) async {
    final GoRouter router = buildRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameControllerProvider.overrideWith(
            (ref) => _FakeGameController(),
          ),
        ],
        child: buildTestMaterialAppRouter(
          routerConfig: router,
          locale: const Locale('en'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ResultScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('ResultScreen system back navigates to home', (tester) async {
    final GoRouter router = buildRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameControllerProvider.overrideWith(
            (ref) => _FakeGameController(),
          ),
        ],
        child: buildTestMaterialAppRouter(
          routerConfig: router,
          locale: const Locale('en'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ResultScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('ResultScreen does not show play again button', (tester) async {
    final GoRouter router = buildRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameControllerProvider.overrideWith(
            (ref) => _FakeGameController(),
          ),
        ],
        child: buildTestMaterialAppRouter(
          routerConfig: router,
          locale: const Locale('en'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Play again'), findsNothing);
  });

  testWidgets('ResultScreen keeps frozen results even if live state changes',
      (tester) async {
    final GoRouter router = buildRouter();
    final GameState frozenState = GameState.initial().copyWith(
      players: const <Player>[
        Player(id: 'p1', name: 'You', score: 100),
        Player(id: 'p2', name: 'Bot', score: 50),
      ],
      phase: GamePhase.finished,
      isMatchEnded: true,
      winnerId: 'p1',
    );
    final _MutableResultGameController controller =
        _MutableResultGameController(frozenState);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameControllerProvider.overrideWith((ref) => controller),
          matchResultSnapshotProvider.overrideWith((ref) => frozenState),
        ],
        child: buildTestMaterialAppRouter(
          routerConfig: router,
          locale: const Locale('en'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You'), findsWidgets);
    expect(find.text('100 pts'), findsOneWidget);

    controller.replaceState(
      frozenState.copyWith(
        players: const <Player>[
          Player(id: 'p2', name: 'Bot', score: 999),
        ],
        winnerId: 'p2',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You'), findsWidgets);
    expect(find.text('100 pts'), findsOneWidget);
    expect(find.text('999'), findsNothing);
    expect(find.text('999 pts'), findsNothing);
  });
}
