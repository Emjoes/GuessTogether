import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:guesstogether/features/game/domain/game_models.dart';
import 'package:guesstogether/features/game/presentation/game_screen.dart';
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
      phase: GamePhase.boardSelection,
      phaseSecondsLeft: 20,
      phaseSecondsTotal: 20,
    );
  }

  @override
  Future<void> startMatch() async {}
}

class _FinishableGameController extends GameController {
  _FinishableGameController() : super(enableLocalTimers: false) {
    state = GameState.initial().copyWith(
      players: const <Player>[
        Player(id: 'p1', name: 'You', score: 100),
        Player(id: 'p2', name: 'Bot', score: 50),
      ],
      phase: GamePhase.boardSelection,
      phaseSecondsLeft: 20,
      phaseSecondsTotal: 20,
    );
  }

  @override
  Future<void> startMatch() async {}

  @override
  void finishMatchNow() {
    state = state.copyWith(
      phase: GamePhase.finished,
      isMatchEnded: true,
      winnerId: 'p1',
      phaseSecondsLeft: 0,
      phaseSecondsTotal: 0,
      lastEvent: 'Match finished.',
    );
  }
}

class _QuestionRevealGameController extends GameController {
  _QuestionRevealGameController() : super(enableLocalTimers: false) {
    const Question selectedQuestion = Question(
      id: 'q1',
      text: 'Unique question body',
      answer: 'Answer',
      category: 'Science',
      value: 300,
      used: true,
    );
    state = GameState.initial(
      players: const <Player>[
        Player(id: 'p1', name: 'You', score: 100),
        Player(id: 'p2', name: 'Bot', score: 50),
      ],
      boardQuestions: const <Question>[
        selectedQuestion,
        Question(
          id: 'q2',
          text: 'Another question',
          answer: 'Another answer',
          category: 'Science',
          value: 500,
          used: false,
        ),
      ],
    ).copyWith(
      currentQuestion: selectedQuestion,
      phase: GamePhase.questionReveal,
      phaseSecondsLeft: 2,
      phaseSecondsTotal: 2,
    );
  }

  @override
  Future<void> startMatch() async {}
}

class _RoundShortcutGameController extends GameController {
  _RoundShortcutGameController() : super(enableLocalTimers: false) {
    state = GameState.initial(
      players: const <Player>[
        Player(id: 'p1', name: 'You', score: 100),
        Player(id: 'p2', name: 'Bot', score: 50),
      ],
      boardQuestions: const <Question>[
        Question(
          id: 'r1_q1',
          text: 'Round 1 clue',
          answer: 'A1',
          category: 'History',
          value: 100,
          used: false,
          round: 1,
        ),
        Question(
          id: 'r2_q1',
          text: 'Round 2 clue',
          answer: 'B1',
          category: 'Science',
          value: 200,
          used: false,
          round: 2,
        ),
      ],
    ).copyWith(
      phase: GamePhase.boardSelection,
      phaseSecondsLeft: 20,
      phaseSecondsTotal: 20,
    );
  }

  @override
  Future<void> startMatch() async {}
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('GameScreen shows player row', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameControllerProvider.overrideWith(
            (ref) => _FakeGameController(),
          ),
        ],
        child: buildTestMaterialApp(
          home: const GameScreen(),
          locale: const Locale('en'),
        ),
      ),
    );

    expect(find.text('You'), findsOneWidget);
    expect(find.text('Bot'), findsOneWidget);
  });

  testWidgets('GameScreen keeps board visible during question reveal',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameControllerProvider.overrideWith(
            (ref) => _QuestionRevealGameController(),
          ),
        ],
        child: buildTestMaterialApp(
          home: const GameScreen(),
          locale: const Locale('en'),
        ),
      ),
    );

    expect(find.text('Unique question body'), findsNothing);
    expect(find.text('300'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
  });

  testWidgets('Host can use space to randomly pick a question', (tester) async {
    final _FakeGameController controller = _FakeGameController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameControllerProvider.overrideWith((ref) => controller),
          gameViewRoleProvider.overrideWith((ref) => GameViewRole.host),
        ],
        child: buildTestMaterialApp(
          home: const GameScreen(),
          locale: const Locale('en'),
        ),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 320));

    expect(controller.state.phase, GamePhase.questionReveal);
    expect(controller.state.currentQuestion, isNotNull);
  });

  testWidgets('Host can use double space to skip the round', (tester) async {
    final _RoundShortcutGameController controller =
        _RoundShortcutGameController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameControllerProvider.overrideWith((ref) => controller),
          gameViewRoleProvider.overrideWith((ref) => GameViewRole.host),
        ],
        child: buildTestMaterialApp(
          home: const GameScreen(),
          locale: const Locale('en'),
        ),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.state.round, 2);
    expect(controller.state.phase, GamePhase.boardSelection);
  });

  testWidgets('Tapping player tile does not open manual score dialog',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameControllerProvider.overrideWith(
            (ref) => _FakeGameController(),
          ),
        ],
        child: buildTestMaterialApp(
          home: const GameScreen(),
          locale: const Locale('en'),
        ),
      ),
    );

    await tester.tap(find.text('You'));
    await _pumpUi(tester);

    expect(find.text('Set score: You'), findsNothing);
  });

  testWidgets('Back action shows leave confirmation with reconnect hint',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameControllerProvider.overrideWith(
            (ref) => _FakeGameController(),
          ),
          gameViewRoleProvider.overrideWith((ref) => GameViewRole.player),
        ],
        child: buildTestMaterialApp(
          home: const GameScreen(),
          locale: const Locale('en'),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await _pumpUi(tester);

    expect(find.text('Leave match?'), findsOneWidget);
    expect(
      find.text('You can reconnect to this match later.'),
      findsOneWidget,
    );
  });

  testWidgets('Escape action shows leave confirmation with reconnect hint',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameControllerProvider.overrideWith(
            (ref) => _FakeGameController(),
          ),
          gameViewRoleProvider.overrideWith((ref) => GameViewRole.player),
        ],
        child: buildTestMaterialApp(
          home: const GameScreen(),
          locale: const Locale('en'),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _pumpUi(tester);

    expect(find.text('Leave match?'), findsOneWidget);
    expect(
      find.text('You can reconnect to this match later.'),
      findsOneWidget,
    );
  });

  testWidgets('Host leave confirmation warns that the room will be destroyed',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gameControllerProvider.overrideWith(
            (ref) => _FakeGameController(),
          ),
          gameViewRoleProvider.overrideWith((ref) => GameViewRole.host),
        ],
        child: buildTestMaterialApp(
          home: const GameScreen(),
          locale: const Locale('en'),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await _pumpUi(tester);

    expect(find.text('Leave match?'), findsOneWidget);
    expect(
      find.text(
        'If the host leaves, the room will be destroyed for all players.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Players see host-left message when match room is closed',
      (tester) async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        gameControllerProvider.overrideWith(
          (ref) => _FakeGameController(),
        ),
        gameViewRoleProvider.overrideWith((ref) => GameViewRole.player),
      ],
    );
    addTearDown(container.dispose);

    final GoRouter router = GoRouter(
      initialLocation: GameScreen.routePath,
      routes: <RouteBase>[
        GoRoute(
          path: GameScreen.routePath,
          builder: (context, state) => const GameScreen(),
        ),
        GoRoute(
          path: HomeScreen.routePath,
          builder: (context, state) => const HomeScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: buildTestMaterialAppRouter(
          routerConfig: router,
          locale: const Locale('en'),
        ),
      ),
    );
    await _pumpUi(tester);

    container.read(matchRoomClosedReasonProvider.notifier).state =
        MatchRoomClosedReason.hostLeft;
    container.read(matchRoomClosedProvider.notifier).state = true;
    await _pumpUi(tester);

    expect(find.text('Host left the game - match was ended'), findsOneWidget);
    expect(find.text('Create Room'), findsOneWidget);
  });

  testWidgets('Finished match stays on results when room closes later',
      (tester) async {
    final _FinishableGameController controller = _FinishableGameController();

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        gameControllerProvider.overrideWith((ref) => controller),
        gameViewRoleProvider.overrideWith((ref) => GameViewRole.player),
      ],
    );
    addTearDown(container.dispose);

    final GoRouter router = GoRouter(
      initialLocation: GameScreen.routePath,
      routes: <RouteBase>[
        GoRoute(
          path: GameScreen.routePath,
          builder: (context, state) => const GameScreen(),
        ),
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: buildTestMaterialAppRouter(
          routerConfig: router,
          locale: const Locale('en'),
        ),
      ),
    );
    await _pumpUi(tester);

    controller.finishMatchNow();
    await _pumpUi(tester);

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(container.read(matchResultSnapshotProvider)?.isMatchEnded, isTrue);

    container.read(matchRoomClosedReasonProvider.notifier).state =
        MatchRoomClosedReason.hostLeft;
    container.read(matchRoomClosedProvider.notifier).state = true;
    await _pumpUi(tester);

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(container.read(matchResultSnapshotProvider)?.isMatchEnded, isTrue);
    expect(find.text('Create Room'), findsNothing);
  });
}
