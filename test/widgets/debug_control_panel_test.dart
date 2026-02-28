import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/core/debug/debug_control_panel.dart';
import 'package:guesstogether/features/game/providers/game_providers.dart';

Future<void> _pumpPanel(
  WidgetTester tester,
  ProviderContainer container, {
  ThemeMode mode = ThemeMode.light,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: mode,
        home: const Stack(
          children: <Widget>[
            SizedBox.expand(),
            DebugControlPanel(),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Debug panel renders in light theme', (tester) async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpPanel(tester, container, mode: ThemeMode.light);
    await tester.pumpAndSettle();

    expect(find.text('DEBUG PANEL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Debug panel renders in dark theme', (tester) async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpPanel(tester, container, mode: ThemeMode.dark);
    await tester.pumpAndSettle();

    expect(find.text('DEBUG PANEL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Debug role buttons switch host/player mode', (tester) async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpPanel(tester, container);
    await tester.pumpAndSettle();

    expect(container.read(gameViewRoleProvider), GameViewRole.host);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Player'));
    await tester.pumpAndSettle();
    expect(container.read(gameViewRoleProvider), GameViewRole.player);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Host'));
    await tester.pumpAndSettle();
    expect(container.read(gameViewRoleProvider), GameViewRole.host);
  });

  testWidgets('Debug local player selector updates provider', (tester) async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpPanel(tester, container);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Player'));
    await tester.pumpAndSettle();
    expect(container.read(gameViewRoleProvider), GameViewRole.player);

    await tester.tap(find.text('P3').last);
    await tester.pumpAndSettle();

    expect(container.read(localPlayerIdProvider), 'p3');
  });

  testWidgets('Debug finish match button ends current match', (tester) async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final ProviderSubscription subscription = container.listen(
      gameControllerProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await _pumpPanel(tester, container);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Finish Match'));
    await tester.pumpAndSettle();

    final state = container.read(gameControllerProvider);
    expect(state.isMatchEnded, true);
    expect(state.phase.name, 'finished');
  });
}
