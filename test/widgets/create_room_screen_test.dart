import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guesstogether/features/lobby/presentation/create_room_screen.dart';

void main() {
  testWidgets('CreateRoomScreen rounds increment/decrement', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CreateRoomScreen(),
        ),
      ),
    );

    // Default rounds is 3.
    expect(find.text('3'), findsOneWidget);

    // Tap + increases.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('4'), findsOneWidget);

    // Tap - decreases.
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
  });
}

