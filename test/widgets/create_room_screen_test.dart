import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
import 'package:guesstogether/features/lobby/presentation/create_room_screen.dart';
import 'package:guesstogether/features/lobby/providers/create_room_provider.dart';

void main() {
  testWidgets('CreateRoomScreen shows required fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CreateRoomScreen(),
        ),
      ),
    );

    expect(find.text(AppStrings.createRoomNameLabel), findsOneWidget);
    expect(find.text(AppStrings.createRoomPasswordLabel), findsOneWidget);
    expect(find.text(AppStrings.createRoomModeMultiplayer), findsOneWidget);
    expect(find.text(AppStrings.createRoomModeDuel), findsOneWidget);
    expect(find.text(AppStrings.createRoomPlayersLabel), findsNothing);
    expect(find.text(AppStrings.createRoomDuelHint), findsNothing);
  });

  testWidgets('CreateRoomScreen updates mode when tapping duel', (tester) async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CreateRoomScreen()),
      ),
    );

    await tester.tap(find.text(AppStrings.createRoomModeDuel));
    await tester.pumpAndSettle();

    expect(
      container.read(createRoomControllerProvider).mode,
      RoomMode.duel,
    );
  });
}
