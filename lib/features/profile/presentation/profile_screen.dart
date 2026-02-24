import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
import 'package:guesstogether/core/theme/app_spacing.dart';
import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/data/api/mock_http_adapter.dart';
import 'package:guesstogether/widgets/app_panel.dart';

final profileProvider = FutureProvider<ProfileSummary>((ref) async {
  final GameApi api = MockHttpAdapter();
  return api.loadProfile();
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const String routePath = '/profile';
  static const String routeName = 'profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profileTitle),
      ),
      body: SafeArea(
        child: asyncProfile.when(
          data: (ProfileSummary profile) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppPanel(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color(0xFF244575),
                        Color(0xFF173058),
                      ],
                    ),
                    child: Row(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 34,
                          child: Text(profile.displayName[0]),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                profile.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Competitive quiz player',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.75),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      _StatTile(
                        label: AppStrings.profileGamesPlayed,
                        value: profile.gamesPlayed.toString(),
                      ),
                      _StatTile(
                        label: AppStrings.profileWinRate,
                        value: '${(profile.winRate * 100).round()}%',
                      ),
                      _StatTile(
                        label: AppStrings.profileBestScore,
                        value: profile.bestScore.toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          AppStrings.profileAchievements,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: <Widget>[
                            Chip(label: Text('Night Owl')),
                            Chip(label: Text('Perfect Round')),
                            Chip(label: Text('Fast Fingers')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace st) =>
              const Center(child: Text('Failed to load profile')),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      child: AppPanel(
        padding: const EdgeInsets.all(AppSpacing.md),
        radius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
