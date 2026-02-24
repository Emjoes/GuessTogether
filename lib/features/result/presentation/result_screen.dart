import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
import 'package:guesstogether/core/theme/app_colors.dart';
import 'package:guesstogether/core/theme/app_spacing.dart';
import 'package:guesstogether/features/game/providers/game_providers.dart';
import 'package:guesstogether/features/home/presentation/home_screen.dart';
import 'package:guesstogether/widgets/app_panel.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  static const String routePath = '/results';
  static const String routeName = 'results';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final players = [...game.players]..sort(
        (a, b) => b.score.compareTo(a.score),
      );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.resultsTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (players.isNotEmpty)
                AppPanel(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFF3A2D12),
                      Color(0xFF1E1933),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.accentSun,
                        size: 36,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Winner',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                            Text(
                              players.first.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                            Text(
                              '${players.first.score} pts',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.separated(
                  itemCount: players.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (BuildContext context, int index) {
                    final p = players[index];
                    return AppPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      radius: 18,
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 16,
                            child: Text('${index + 1}'),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Text(p.name)),
                          Text(
                            '${p.score}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => context.go(HomeScreen.routePath),
                icon: const Icon(Icons.replay_rounded),
                label: const Text(AppStrings.resultsPlayAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
