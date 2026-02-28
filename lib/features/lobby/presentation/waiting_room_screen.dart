import 'package:flutter/material.dart';

import 'package:guesstogether/core/l10n/l10n.dart';
import 'package:guesstogether/core/theme/app_spacing.dart';
import 'package:guesstogether/widgets/app_panel.dart';
import 'package:guesstogether/widgets/back_shortcut_scope.dart';

class WaitingRoomScreen extends StatelessWidget {
  const WaitingRoomScreen({super.key});

  static const String routePath = '/waiting-room';
  static const String routeName = 'waitingRoom';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final TextTheme text = Theme.of(context).textTheme;
    return BackShortcutScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.waitingRoomTitle),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.gameWaitingForPlayers,
                    style: text.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.waitingRoomHostPreparing,
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const LinearProgressIndicator(),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.waitingRoomSyncingPlayers,
                    style: text.bodySmall,
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
