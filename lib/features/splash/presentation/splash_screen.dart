import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:guesstogether/core/app_version_gate.dart';
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
    final AsyncValue<AppVersionGateState> versionAsync =
        ref.watch(appVersionGateProvider);
    final AsyncValue<AppSessionState> sessionAsync =
        ref.watch(appSessionControllerProvider);
    final AppVersionGateState? versionState = versionAsync.valueOrNull;

    if (versionState?.requiresUpdate == true) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _UpdateRequiredCard(versionState: versionState!),
            ),
          ),
        ),
      );
    }

    if (versionAsync.isLoading || sessionAsync.isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

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

class _UpdateRequiredCard extends StatelessWidget {
  const _UpdateRequiredCard({required this.versionState});

  final AppVersionGateState versionState;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isRussian =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ru';
    final String title = isRussian ? 'Требуется обновление' : 'Update required';
    final String body = isRussian
        ? 'У вас установлена версия v${versionState.currentVersion}. Чтобы продолжить, обновите приложение до v${versionState.latestVersion}.'
        : 'You are using v${versionState.currentVersion}. Update the app to v${versionState.latestVersion} to continue.';
    final String hint = isRussian
        ? 'Дальнейшая работа с приложением заблокирована до обновления.'
        : 'The app stays locked until it is updated.';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Card(
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.system_update_rounded,
                size: 40,
                color: scheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
