import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
import 'package:guesstogether/core/theme/app_spacing.dart';
import 'package:guesstogether/features/game/domain/game_models.dart';
import 'package:guesstogether/features/game/providers/game_providers.dart';
import 'package:guesstogether/features/result/presentation/result_screen.dart';
import 'package:guesstogether/widgets/app_panel.dart';
import 'package:guesstogether/widgets/circle_timer.dart';
import 'package:guesstogether/widgets/player_row.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  static const String routePath = '/game';
  static const String routeName = 'game';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    ref.listen(
      gameControllerProvider,
      (previous, next) {
        if (previous?.isMatchEnded == false &&
            next.isMatchEnded &&
            context.mounted) {
          context.push(ResultScreen.routePath);
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Match'),
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
              AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            game.currentQuestion?.category ??
                                AppStrings.gameTapToReveal,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        CircleTimer(
                          remaining: game.remainingSeconds,
                          total: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PlayerRow(players: game.players),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _GameBoardOrQuestion(game: game),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: AppSpacing.tapTargetMin + 4,
                child: FilledButton.icon(
                  onPressed: game.isMatchEnded
                      ? null
                      : () {
                          controller.startMatch();
                        },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    game.isMatchEnded
                        ? 'Match ended'
                        : (game.players.isEmpty
                            ? 'Start scripted match'
                            : AppStrings.gameAnswerCta),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameBoardOrQuestion extends StatelessWidget {
  const _GameBoardOrQuestion({required this.game});

  final GameState game;

  @override
  Widget build(BuildContext context) {
    if (game.currentQuestion != null) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        child: AppPanel(
          key: ValueKey<String>(game.currentQuestion!.id),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF1C2140),
              Color(0xFF2C2F52),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  game.currentQuestion!.category,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  game.currentQuestion!.text,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Chip(
                  label: Text('${game.currentQuestion!.value} pts'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<String> categories = <String>[
      'Space 200',
      'Science 200',
      'Geography 400',
      'History 400',
    ];

    return GridView.builder(
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.15,
      ),
      itemBuilder: (BuildContext context, int index) {
        final String label = categories[index];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {},
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: index.isEven
                    ? const <Color>[Color(0xFF173057), Color(0xFF23407D)]
                    : const <Color>[Color(0xFF2B2E56), Color(0xFF3C416E)],
              ),
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
          ),
        );
      },
    );
  }
}
