import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
import 'package:guesstogether/features/lobby/presentation/create_room_screen.dart';
import 'package:guesstogether/features/lobby/providers/create_room_provider.dart';
import 'package:guesstogether/widgets/app_panel.dart';
import '../test_app.dart';

void main() {
  testWidgets('CreateRoomScreen shows required fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: _CreateRoomApp(),
      ),
    );

    expect(find.text(AppStrings.createRoomNameLabel), findsOneWidget);
    expect(find.text(AppStrings.createRoomPasswordLabel), findsOneWidget);
    expect(find.text(AppStrings.createRoomDetailsLabel), findsOneWidget);
    expect(find.text(AppStrings.createRoomModeMultiplayer), findsOneWidget);
    expect(
      find.text(
        '${AppStrings.createRoomModeDuel} (${AppStrings.createRoomPackageSoon})',
      ),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.createRoomPackageLabel),
      findsOneWidget,
    );
    expect(find.text(AppStrings.createRoomPackageEmpty), findsNothing);
    expect(find.text(defaultRoomPackageFileName), findsNothing);
    expect(
      find.text(
        '${AppStrings.createRoomPackagePick} (${AppStrings.createRoomPackageSoon})',
      ),
      findsOneWidget,
    );
    expect(find.text(AppStrings.createRoomPlayersLabel), findsNothing);
    expect(find.text(AppStrings.createRoomDuelHint), findsNothing);
    expect(find.byType(AppPanel), findsNWidgets(3));
  });

  testWidgets('CreateRoomScreen keeps elimination mode disabled',
      (tester) async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final ProviderSubscription<CreateRoomState> subscription = container.listen(
      createRoomControllerProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: buildTestMaterialApp(
          home: const CreateRoomScreen(),
          locale: const Locale('en'),
        ),
      ),
    );

    await tester.tap(
      find.text(
        '${AppStrings.createRoomModeDuel} (${AppStrings.createRoomPackageSoon})',
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      container.read(createRoomControllerProvider).mode,
      RoomMode.multiplayer,
    );
  });

  testWidgets('CreateRoomScreen resets hidden form state on open',
      (tester) async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final ProviderSubscription<CreateRoomState> subscription = container.listen(
      createRoomControllerProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final CreateRoomController controller =
        container.read(createRoomControllerProvider.notifier);
    controller.setName('Old Room');
    controller.setPassword('4321');
    controller.setMode(RoomMode.duel);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: buildTestMaterialApp(
          home: const CreateRoomScreen(),
          locale: const Locale('en'),
        ),
      ),
    );
    await tester.pump();

    final CreateRoomState state = container.read(createRoomControllerProvider);
    expect(state.name, isEmpty);
    expect(state.password, isEmpty);
    expect(state.mode, RoomMode.multiplayer);
  });
}

class _CreateRoomApp extends StatelessWidget {
  const _CreateRoomApp();

  @override
  Widget build(BuildContext context) {
    return buildTestMaterialApp(
      home: const CreateRoomScreen(),
      locale: const Locale('en'),
    );
  }
}
