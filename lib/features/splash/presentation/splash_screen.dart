import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:guesstogether/features/auth/presentation/auth_screen.dart';
import 'package:guesstogether/features/home/presentation/home_screen.dart';
import 'package:guesstogether/features/session/app_session_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const String routePath = '/';
  static const String routeName = 'splash';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _redirectScheduled = false;

  void _scheduleRedirect(String path) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _redirectScheduled) {
        return;
      }
      _redirectScheduled = true;
      context.go(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AppSessionState> sessionAsync =
        ref.watch(appSessionControllerProvider);
    sessionAsync.whenData((AppSessionState state) {
      _scheduleRedirect(
        state.isAuthenticated ? HomeScreen.routePath : AuthScreen.routePath,
      );
    });
    if (sessionAsync.hasError) {
      _scheduleRedirect(AuthScreen.routePath);
    }

    return const Scaffold(
      body: SafeArea(
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
