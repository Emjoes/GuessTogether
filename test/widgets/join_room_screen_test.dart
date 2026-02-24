import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
import 'package:guesstogether/features/lobby/presentation/join_room_screen.dart';

void main() {
  testWidgets('JoinRoomScreen shows active lobbies table', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: JoinRoomScreen(),
        ),
      ),
    );

    expect(find.text(AppStrings.joinRoomActiveLobbies), findsOneWidget);
    expect(find.text(AppStrings.joinRoomSearchLabel), findsOneWidget);
    expect(find.text(AppStrings.joinRoomSearchHint), findsOneWidget);
    expect(find.text(AppStrings.joinRoomTableRoom), findsOneWidget);
    expect(find.text(AppStrings.joinRoomTablePlayers), findsOneWidget);
    expect(find.text(AppStrings.joinRoomTableType), findsOneWidget);
    expect(find.text(AppStrings.joinRoomTablePassword), findsOneWidget);
    expect(find.text('Friday Trivia Crew'), findsOneWidget);
    expect(find.textContaining('#'), findsNothing);
  });

  testWidgets('JoinRoomScreen filters rooms by name', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: JoinRoomScreen(),
        ),
      ),
    );

    expect(find.text('Friday Trivia Crew'), findsOneWidget);
    expect(find.text('Movie Legends'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'movie');
    await tester.pumpAndSettle();

    expect(find.text('Friday Trivia Crew'), findsNothing);
    expect(find.text('Movie Legends'), findsOneWidget);
  });

  testWidgets('JoinRoomScreen opens password dialog safely', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: JoinRoomScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Friday Trivia Crew'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.joinRoomPasswordDialogTitle), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(TextButton).first);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.joinRoomPasswordDialogTitle), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
