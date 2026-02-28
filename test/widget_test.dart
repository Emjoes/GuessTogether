import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/features/home/presentation/home_screen.dart';
import 'package:guesstogether/main.dart';

void main() {
  testWidgets('App redirects from splash to home screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GuessTogetherApp()));

    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
