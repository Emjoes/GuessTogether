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
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: HomeScreen.routePath,
        name: HomeScreen.routeName,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: CreateRoomScreen.routePath,
        name: CreateRoomScreen.routeName,
        builder: (context, state) => const CreateRoomScreen(),
      ),
      GoRoute(
        path: JoinRoomScreen.routePath,
        name: JoinRoomScreen.routeName,
        builder: (context, state) => const JoinRoomScreen(),
      ),
      GoRoute(
        path: WaitingRoomScreen.routePath,
        name: WaitingRoomScreen.routeName,
        builder: (context, state) => const WaitingRoomScreen(),
      ),
      GoRoute(
        path: ProfileScreen.routePath,
        name: ProfileScreen.routeName,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: SettingsScreen.routePath,
        name: SettingsScreen.routeName,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: GameScreen.routePath,
        name: GameScreen.routeName,
        builder: (context, state) => const GameScreen(),
      ),
      GoRoute(
        path: ResultScreen.routePath,
        name: ResultScreen.routeName,
        builder: (context, state) => const ResultScreen(),
      ),
    ],
  ),
);
