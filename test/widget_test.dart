import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:guesstogether/data/api/backend_models.dart';
import 'package:guesstogether/core/debug/debug_control_panel.dart';
import 'package:guesstogether/features/auth/presentation/auth_screen.dart';
import 'package:guesstogether/main.dart';

void main() {
  testWidgets('App redirects from splash to auth when session is missing',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const ProviderScope(child: GuessTogetherApp()));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(DebugControlPanel), findsNothing);
  });

  testWidgets('App starts logged out even when a saved session exists',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app.session': jsonEncode(
        const AuthSession(
          playerId: 'user-1',
          sessionToken: 'session-token',
          displayName: 'Serge',
          email: 'serge@example.com',
        ).toJson(),
      ),
    });

    await tester.pumpWidget(const ProviderScope(child: GuessTogetherApp()));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AuthScreen), findsOneWidget);
  });
}
