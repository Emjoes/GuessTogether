import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:guesstogether/core/l10n/l10n.dart';
import 'package:guesstogether/core/theme/app_colors.dart';
import 'package:guesstogether/core/theme/app_spacing.dart';
import 'package:guesstogether/features/game/providers/game_providers.dart';
import 'package:guesstogether/features/home/presentation/home_screen.dart';
import 'package:guesstogether/widgets/app_panel.dart';
import 'package:guesstogether/widgets/back_shortcut_scope.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  static const String routePath = '/results';
  static const String routeName = 'results';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final game = ref.watch(gameControllerProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;
    final players = [...game.players]..sort(
        (a, b) => b.score.compareTo(a.score),
      );
    final Gradient winnerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color.alphaBlend(
          Colors.white.withValues(alpha: isLight ? 0.18 : 0.08),
          scheme.surfaceContainerHighest
              .withValues(alpha: isLight ? 0.86 : 0.56),
        ),
        Color.alphaBlend(
          scheme.tertiary.withValues(alpha: isLight ? 0.2 : 0.3),
          scheme.surfaceContainerHighest
              .withValues(alpha: isLight ? 0.84 : 0.52),
        ),
        Color.alphaBlend(
          scheme.primary.withValues(alpha: isLight ? 0.12 : 0.2),
          scheme.surfaceContainerHighest.withValues(alpha: isLight ? 0.8 : 0.5),
        ),
      ],
    );
    final Color winnerPrimaryText = isLight ? scheme.onSurface : Colors.white;
    final Color winnerSecondaryText =
        isLight ? scheme.onSurfaceVariant : Colors.white70;

    return BackShortcutScope(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (!didPop) {
            context.go(HomeScreen.routePath);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () => context.go(HomeScreen.routePath),
            ),
            title: Text(l10n.resultsTitle),
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
                      gradient: winnerGradient,
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
                                  l10n.resultWinner,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: winnerSecondaryText),
                                ),
                                Text(
                                  players.first.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(color: winnerPrimaryText),
                                ),
                                Text(
                                  l10n.resultPointsLabel(players.first.score),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: winnerSecondaryText),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
