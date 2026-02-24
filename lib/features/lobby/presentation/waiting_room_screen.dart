import 'package:flutter/material.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
import 'package:guesstogether/core/theme/app_spacing.dart';
import 'package:guesstogether/widgets/app_panel.dart';

class WaitingRoomScreen extends StatelessWidget {
  const WaitingRoomScreen({super.key});

  static const String routePath = '/waiting-room';
  static const String routeName = 'waitingRoom';

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiting Room'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppStrings.gameWaitingForPlayers,
                  style: text.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Host is preparing the board. Stay on this screen.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                const LinearProgressIndicator(),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Syncing players...',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
