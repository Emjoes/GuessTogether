import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            _buildAppPage(state: state, child: const SplashScreen()),
      ),
      GoRoute(
        path: HomeScreen.routePath,
        name: HomeScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildAppPage(state: state, child: const HomeScreen()),
      ),
      GoRoute(
        path: CreateRoomScreen.routePath,
        name: CreateRoomScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildAppPage(state: state, child: const CreateRoomScreen()),
      ),
      GoRoute(
        path: JoinRoomScreen.routePath,
        name: JoinRoomScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildAppPage(state: state, child: const JoinRoomScreen()),
      ),
      GoRoute(
        path: WaitingRoomScreen.routePath,
        name: WaitingRoomScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildAppPage(state: state, child: const WaitingRoomScreen()),
      ),
      GoRoute(
        path: ProfileScreen.routePath,
        name: ProfileScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildAppPage(state: state, child: const ProfileScreen()),
      ),
      GoRoute(
        path: SettingsScreen.routePath,
        name: SettingsScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildAppPage(state: state, child: const SettingsScreen()),
      ),
      GoRoute(
        path: GameScreen.routePath,
        name: GameScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildAppPage(state: state, child: const GameScreen()),
      ),
      GoRoute(
        path: ResultScreen.routePath,
        name: ResultScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildAppPage(state: state, child: const ResultScreen()),
      ),
    ],
  ),
);

CustomTransitionPage<void> _buildAppPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
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
