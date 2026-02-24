import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
import 'package:guesstogether/main.dart';

void main() {
  testWidgets('App renders splash title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GuessTogetherApp()));

    expect(find.text(AppStrings.appTitle), findsOneWidget);

    // Let splash timer complete to avoid pending timer assertion at teardown.
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
  });
}
