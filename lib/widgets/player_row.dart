import 'package:flutter/material.dart';

import 'package:guesstogether/core/l10n/l10n.dart';
import 'package:guesstogether/core/theme/app_spacing.dart';
import 'package:guesstogether/features/game/domain/game_models.dart';

class PlayerRow extends StatelessWidget {
  const PlayerRow({super.key, required this.players});

  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return Text(
        context.l10n.playerRowWaitingRoster,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: players.map((Player player) {
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _PlayerPill(player: player),
          );
        }).toList(),
      ),
    );
  }
}

class _PlayerPill extends StatelessWidget {
  const _PlayerPill({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.68),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircleAvatar(
            radius: 12,
            child: Text(player.name.isNotEmpty ? player.name[0] : '?'),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            player.name,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            player.score.toString(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
