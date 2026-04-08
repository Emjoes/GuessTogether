import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:guesstogether/features/auth/presentation/auth_screen.dart';
import '../test_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('AuthScreen centers login title and hides subtitle',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: _AuthApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == 'Sign in' &&
            widget.textAlign == TextAlign.center,
      ),
      findsOneWidget,
    );
    expect(
      find.text('Enter your email or nickname and password to continue.'),
      findsNothing,
    );
    expect(find.text('Email or nickname'), findsNothing);
    expect(find.text('Nickname'), findsOneWidget);
  });

  testWidgets('AuthScreen centers register title and hides subtitle',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: _AuthApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == 'Create account' &&
            widget.textAlign == TextAlign.center,
      ),
      findsOneWidget,
    );
    expect(
      find.text('Create an account to save your profile, settings and rooms.'),
      findsNothing,
    );
    expect(find.text('Email'), findsNothing);
    expect(find.text('Nickname'), findsOneWidget);
  });
}

class _AuthApp extends StatelessWidget {
  const _AuthApp();

  @override
  Widget build(BuildContext context) {
    return buildTestMaterialApp(
      home: const AuthScreen(),
      locale: const Locale('en'),
    );
  }
}
