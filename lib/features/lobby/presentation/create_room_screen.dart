import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
import 'package:guesstogether/core/theme/app_colors.dart';
import 'package:guesstogether/core/theme/app_spacing.dart';
import 'package:guesstogether/features/game/presentation/game_screen.dart';
import 'package:guesstogether/features/lobby/providers/create_room_provider.dart';
import 'package:guesstogether/widgets/app_icon_button.dart';
import 'package:guesstogether/widgets/app_panel.dart';

class CreateRoomScreen extends ConsumerWidget {
  const CreateRoomScreen({super.key});

  static const String routePath = '/create-room';
  static const String routeName = 'createRoom';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createRoomControllerProvider);
    final controller = ref.read(createRoomControllerProvider.notifier);
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.createRoomTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
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
                    Color(0xFF1E3567),
                    Color(0xFF102345),
                  ],
                ),
                child: Text(
                  'Configure a polished quiz room in under 30 seconds.',
                  style: text.bodyLarge?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Room setup',
                      style: text.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: AppStrings.createRoomNameLabel,
                        hintText: 'Friday Trivia Night',
                      ),
                      onChanged: controller.setName,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: AppStrings.createRoomTopicLabel,
                        hintText: 'Space & Science',
                      ),
                      onChanged: controller.setTopic,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Game mode', style: text.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: RoomMode.values.map((RoomMode mode) {
                        return ChoiceChip(
                          label: Text(mode.label),
                          selected: state.mode == mode,
                          onSelected: (_) => controller.setMode(mode),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPanel(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            AppStrings.createRoomRoundsLabel,
                            style: text.titleMedium,
                          ),
                        ),
                        AppIconButton(
                          icon: Icons.remove_rounded,
                          semanticLabel: 'Decrease rounds',
                          onPressed: () =>
                              controller.setRounds(state.rounds - 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: Text(
                            state.rounds.toString(),
                            style: text.titleLarge,
                          ),
                        ),
                        AppIconButton(
                          icon: Icons.add_rounded,
                          semanticLabel: 'Increase rounds',
                          onPressed: () =>
                              controller.setRounds(state.rounds + 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.groups_rounded,
                          size: 18,
                          color: AppColors.accentMint,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Players: ${state.minPlayers}-${state.maxPlayers}',
                          style: text.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: state.finalWagerEnabled,
                      title: const Text(AppStrings.createRoomFinalWager),
                      onChanged: controller.setFinalWager,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: AppSpacing.tapTargetMin + 4,
                child: FilledButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          await controller.createRoom();
                          if (context.mounted) {
                            context.push(GameScreen.routePath);
                          }
                        },
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.rocket_launch_rounded),
                  label: const Text(AppStrings.createRoomCreateCta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
