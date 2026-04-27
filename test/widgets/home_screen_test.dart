import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guesstogether/features/home/presentation/home_screen.dart';
import 'package:guesstogether/features/lobby/presentation/create_room_screen.dart';
import '../test_app.dart';

void main() {
  testWidgets('HomeScreen navigates to CreateRoom', (tester) async {
    final router = GoRouter(
      initialLocation: HomeScreen.routePath,
      routes: <RouteBase>[
        GoRoute(
          path: HomeScreen.routePath,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: CreateRoomScreen.routePath,
          builder: (context, state) => const CreateRoomScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: buildTestMaterialAppRouter(
          routerConfig: router,
          locale: const Locale('en'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Create Room'), findsOneWidget);
    expect(find.text('v1.0.1'), findsOneWidget);
    await tester.tap(find.text('Create Room'));
    await tester.pumpAndSettle();

    expect(find.text('Create Room'), findsWidgets);
  });
}
