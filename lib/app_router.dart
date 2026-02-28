import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:guesstogether/core/debug/loading_debug_gate.dart';
import 'package:guesstogether/features/game/presentation/game_screen.dart';
import 'package:guesstogether/features/home/presentation/home_screen.dart';
import 'package:guesstogether/features/lobby/presentation/create_room_screen.dart';
import 'package:guesstogether/features/lobby/presentation/join_room_screen.dart';
import 'package:guesstogether/features/lobby/presentation/waiting_room_screen.dart';
import 'package:guesstogether/features/profile/presentation/profile_screen.dart';
import 'package:guesstogether/features/result/presentation/result_screen.dart';
import 'package:guesstogether/features/settings/presentation/settings_screen.dart';
import 'package:guesstogether/features/splash/presentation/splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: SplashScreen.routePath,
    routes: <RouteBase>[
      GoRoute(
        path: SplashScreen.routePath,
        name: SplashScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildAppPage(
          state: state,
          child: const SplashScreen(),
          showEntryLoader: true,
        ),
      ),
      GoRoute(
        path: HomeScreen.routePath,
        name: HomeScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildAppPage(
          state: state,
          child: const HomeScreen(),
          showEntryLoader: false,
        ),
      ),
      GoRoute(
        path: CreateRoomScreen.routePath,
        name: CreateRoomScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildAppPage(
          state: state,
          child: const CreateRoomScreen(),
          showEntryLoader: true,
        ),
      ),
      GoRoute(
        path: JoinRoomScreen.routePath,
        name: JoinRoomScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildAppPage(
          state: state,
          child: const JoinRoomScreen(),
          showEntryLoader: true,
        ),
      ),
      GoRoute(
        path: WaitingRoomScreen.routePath,
        name: WaitingRoomScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildAppPage(
          state: state,
          child: const WaitingRoomScreen(),
          showEntryLoader: true,
        ),
      ),
      GoRoute(
        path: ProfileScreen.routePath,
        name: ProfileScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildAppPage(
              state: state,
              child: const ProfileScreen(),
              showEntryLoader: false,
            ),
      ),
      GoRoute(
        path: SettingsScreen.routePath,
        name: SettingsScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildAppPage(
          state: state,
          child: const SettingsScreen(),
          showEntryLoader: true,
        ),
      ),
      GoRoute(
        path: GameScreen.routePath,
        name: GameScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildAppPage(
          state: state,
          child: const GameScreen(),
          showEntryLoader: true,
        ),
      ),
      GoRoute(
        path: ResultScreen.routePath,
        name: ResultScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildAppPage(
          state: state,
          child: const ResultScreen(),
          showEntryLoader: true,
        ),
      ),
    ],
  ),
);

CustomTransitionPage<void> _buildAppPage({
  required GoRouterState state,
  required Widget child,
  required bool showEntryLoader,
}) {
  final Widget pageChild =
      showEntryLoader ? _RouteEntryLoader(child: child) : child;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: pageChild,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      final Animation<double> easedFade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final Animation<Offset> easedSlide = Tween<Offset>(
        begin: const Offset(0.02, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      );
      return FadeTransition(
        opacity: easedFade,
        child: SlideTransition(
          position: easedSlide,
          child: child,
        ),
      );
    },
  );
}

class _RouteEntryLoader extends StatefulWidget {
  const _RouteEntryLoader({required this.child});

  final Widget child;

  @override
  State<_RouteEntryLoader> createState() => _RouteEntryLoaderState();
}

class _RouteEntryLoaderState extends State<_RouteEntryLoader> {
  bool _ready = !isLoadingDebugGateSupported;

  @override
  void initState() {
    super.initState();
    if (_ready) {
      return;
    }
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    await LoadingDebugGate.instance.delayed(
      const Duration(milliseconds: 260),
    );
    if (!mounted) {
      return;
    }
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return widget.child;
    }
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
