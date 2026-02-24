import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
import 'package:guesstogether/core/theme/app_spacing.dart';
import 'package:guesstogether/features/game/presentation/game_screen.dart';
import 'package:guesstogether/features/lobby/providers/join_room_provider.dart';
import 'package:guesstogether/widgets/app_panel.dart';

class JoinRoomScreen extends ConsumerWidget {
  const JoinRoomScreen({super.key});

  static const String routePath = '/join-room';
  static const String routeName = 'joinRoom';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(joinRoomControllerProvider);
    final controller = ref.read(joinRoomControllerProvider.notifier);
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.joinRoomTitle),
      ),
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
                    Color(0xFF1F3A70),
                    Color(0xFF14284E),
                  ],
                ),
                child: Text(
                  'Enter a 4-digit room code and jump right in.',
                  style: text.bodyLarge?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextField(
                      decoration: InputDecoration(
                        labelText: AppStrings.joinRoomCodeLabel,
                        hintText: '1234',
                        errorText: state.errorText == null
                            ? null
                            : AppStrings.joinRoomErrorInvalid,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: controller.setCode,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: AppSpacing.tapTargetMin + 4,
                      child: FilledButton.icon(
                        onPressed: state.isLoading
                            ? null
                            : () async {
                                await controller.submit();
                                final JoinRoomState latest =
                                    ref.read(joinRoomControllerProvider);
                                if (latest.errorText == null &&
                                    context.mounted) {
                                  context.push(GameScreen.routePath);
                                }
                              },
                        icon: state.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.2),
                              )
                            : const Icon(Icons.login_rounded),
                        label: const Text('Join Room'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppStrings.joinRoomRecent,
                      style: text.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: state.recentCodes.map((String code) {
                        return ActionChip(
                          label: Text(code),
                          onPressed: () => controller.useRecent(code),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      AppStrings.joinRoomQrStub,
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
