import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:guesstogether/core/l10n/l10n.dart';
import 'package:guesstogether/core/theme/app_spacing.dart';
import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/game/presentation/game_screen.dart';
import 'package:guesstogether/features/game/providers/game_providers.dart';
import 'package:guesstogether/features/home/presentation/home_screen.dart';
import 'package:guesstogether/features/lobby/providers/room_session_provider.dart';
import 'package:guesstogether/features/session/app_session_controller.dart';
import 'package:guesstogether/widgets/app_panel.dart';
import 'package:guesstogether/widgets/back_shortcut_scope.dart';

class WaitingRoomScreen extends ConsumerStatefulWidget {
  const WaitingRoomScreen({
    required this.roomId,
    super.key,
  });

  static const String routePath = '/waiting-room/:roomId';
  static const String routeName = 'waitingRoom';

  static String routeLocation(String roomId) => '/waiting-room/$roomId';

  final String roomId;

  @override
  ConsumerState<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends ConsumerState<WaitingRoomScreen> {
  bool _exitDialogOpen = false;

  bool get _isRussian =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'ru';

  String get _roomLoadError =>
      _isRussian ? 'Не удалось загрузить комнату.' : 'Failed to load the room.';

  String get _playersLabel => _isRussian ? 'Игроки' : 'Players';

  String get _hostLabel => _isRussian ? 'Ведущий' : 'Host';

  String get _passwordLabel => _isRussian ? 'Пароль' : 'Password';

  String get _noPasswordText => _isRussian ? 'Без пароля' : 'No password';

  String get _packageLabel => _isRussian ? 'Пакет' : 'Package';

  String get _startMatchLabel => _isRussian ? 'Начать игру' : 'Start match';

  String get _emptyPlayersText => _isRussian
      ? 'Пока нет подключившихся игроков.'
      : 'No players have joined yet.';

  String get _standardPackageText => _isRussian ? 'Стандартный' : 'Standard';

  String get _needPlayersText => _isRussian
      ? 'Для старта нужно минимум 2 игрока, не считая ведущего'
      : 'At least 2 players besides the host are required to start';

  String get _startFailedText =>
      _isRussian ? 'Не удалось запустить матч.' : 'Failed to start the match.';

  @override
  void initState() {
    super.initState();
    ref.listenManual<WaitingRoomState>(
      waitingRoomControllerProvider(widget.roomId),
      (WaitingRoomState? previous, WaitingRoomState next) {
        if (next.errorText == 'room_closed') {
          final String? playerId = ref
              .read(appSessionControllerProvider)
              .valueOrNull
              ?.session
              ?.playerId;
          final RoomDetails? closedRoom = previous?.room;
          final bool shouldShowHostLeftMessage = closedRoom != null &&
              playerId != null &&
              closedRoom.hostPlayerId != playerId;
          ref.read(activeRoomProvider.notifier).state = null;
          if (mounted) {
            if (shouldShowHostLeftMessage) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.gameHostLeftMatchMessage),
                ),
              );
            }
            context.go(HomeScreen.routePath);
          }
          return;
        }
        if (mounted &&
            next.errorText != null &&
            next.errorText != previous?.errorText &&
            next.errorText != 'load_failed' &&
            next.errorText != 'realtime_failed') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                next.errorText == 'start_failed'
                    ? _startFailedText
                    : next.errorText!,
              ),
            ),
          );
        }
        if (!mounted || !next.hasStarted || next.room == null) {
          return;
        }
        if (previous?.hasStarted == true) {
          return;
        }

        final String? playerId = ref
            .read(appSessionControllerProvider)
            .valueOrNull
            ?.session
            ?.playerId;
        if (playerId != null && playerId.isNotEmpty) {
          ref.read(localPlayerIdProvider.notifier).state = playerId;
          ref.read(gameViewRoleProvider.notifier).state =
              next.room!.hostPlayerId == playerId
                  ? GameViewRole.host
                  : GameViewRole.player;
        }
        context.go(GameScreen.routePath);
      },
    );
  }

  Future<bool> _confirmHostLeaveRoom() async {
    final l10n = context.l10n;
    final bool? shouldLeave = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.gameLeaveDialogTitle),
          content: Text(l10n.gameLeaveDialogBodyHost),
          actions: <Widget>[
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(
                  dialogContext,
                ).colorScheme.surfaceContainerHighest,
                foregroundColor: Theme.of(
                  dialogContext,
                ).colorScheme.onSurfaceVariant,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.gameLeaveStay),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.gameLeaveLeave),
            ),
          ],
        );
      },
    );
    return shouldLeave ?? false;
  }

  Future<void> _leaveRoom() async {
    await ref
        .read(waitingRoomControllerProvider(widget.roomId).notifier)
        .leaveRoom();
    if (!mounted) {
      return;
    }
    context.go(HomeScreen.routePath);
  }

  Future<void> _attemptLeaveRoom({required bool isHost}) async {
    if (!mounted) {
      return;
    }
    if (!isHost) {
      await _leaveRoom();
      return;
    }
    if (_exitDialogOpen) {
      return;
    }

    _exitDialogOpen = true;
    try {
      final bool shouldLeave = await _confirmHostLeaveRoom();
      if (shouldLeave && mounted) {
        await _leaveRoom();
      }
    } finally {
      _exitDialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final WaitingRoomState state =
        ref.watch(waitingRoomControllerProvider(widget.roomId));
    final String? playerId =
        ref.watch(appSessionControllerProvider).valueOrNull?.session?.playerId;
    final RoomDetails? room = state.room;
    final bool isHost = room != null && room.hostPlayerId == playerId;
    final RoomParticipant? hostParticipant = room?.hostParticipant;
    final List<RoomParticipant> players =
        room?.playerParticipants ?? const <RoomParticipant>[];
    final bool canStart = room?.summary.canStartMatch ?? false;
    final String playerWaitingStatusText =
        canStart ? l10n.waitingRoomHostPreparing : _needPlayersText;
    final String? hostWaitingStatusText = canStart ? null : _needPlayersText;

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;
    final Gradient panelGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color.alphaBlend(
          Colors.white.withValues(alpha: isLight ? 0.18 : 0.08),
          scheme.surfaceContainerHighest
              .withValues(alpha: isLight ? 0.82 : 0.58),
        ),
        Color.alphaBlend(
          scheme.primary.withValues(alpha: isLight ? 0.08 : 0.12),
          scheme.surfaceContainerHighest
              .withValues(alpha: isLight ? 0.72 : 0.5),
        ),
      ],
    );

    return BackShortcutScope(
      child: PopScope<void>(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, void _) async {
          if (didPop) {
            return;
          }
          await _attemptLeaveRoom(isHost: isHost);
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.waitingRoomTitle),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => _attemptLeaveRoom(isHost: isHost),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : room == null
                      ? Center(child: Text(_roomLoadError))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            AppPanel(
                              gradient: panelGradient,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          room.summary.name,
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        '#${room.summary.code}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: scheme.onSurfaceVariant
                                              .withValues(alpha: 0.82),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '$_passwordLabel: ${room.roomPassword.isEmpty ? _noPasswordText : room.roomPassword}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '$_playersLabel: ${room.summary.currentPlayers}/${room.summary.maxPlayers}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  if (hostParticipant != null) ...<Widget>[
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      '$_hostLabel: ${hostParticipant.displayName}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                  if (room
                                      .packageFileName.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      '$_packageLabel: $_standardPackageText',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppPanel(
                              gradient: panelGradient,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Text(
                                    l10n.gameWaitingForPlayers,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  if (players.isEmpty)
                                    Text(
                                      _emptyPlayersText,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: scheme.onSurfaceVariant
                                            .withValues(alpha: 0.9),
                                      ),
                                    )
                                  else
                                    for (int index = 0;
                                        index < players.length;
                                        index++) ...<Widget>[
                                      _ParticipantRow(
                                        participant: players[index],
                                      ),
                                      if (index != players.length - 1)
                                        const SizedBox(height: AppSpacing.sm),
                                    ],
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (isHost) ...<Widget>[
                              if (hostWaitingStatusText != null) ...<Widget>[
                                Text(
                                  hostWaitingStatusText,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant
                                        .withValues(alpha: 0.9),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                              ],
                              SizedBox(
                                height: AppSpacing.tapTargetMin + 4,
                                child: FilledButton.icon(
                                  onPressed: state.isStarting || !canStart
                                      ? null
                                      : () => ref
                                          .read(
                                            waitingRoomControllerProvider(
                                              widget.roomId,
                                            ).notifier,
                                          )
                                          .startRoom(),
                                  icon: state.isStarting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                          ),
                                        )
                                      : const Icon(Icons.play_arrow_rounded),
                                  label: Text(_startMatchLabel),
                                ),
                              ),
                            ] else
                              Text(
                                playerWaitingStatusText,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant
                                      .withValues(alpha: 0.9),
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

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.participant});

  final RoomParticipant participant;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;
    final bool isRussian =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ru';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.32)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(
              Colors.white.withValues(alpha: isLight ? 0.14 : 0.06),
              scheme.surfaceContainerHighest
                  .withValues(alpha: isLight ? 0.66 : 0.5),
            ),
            Color.alphaBlend(
              (participant.isConnected ? scheme.secondary : scheme.primary)
                  .withValues(alpha: isLight ? 0.08 : 0.12),
              scheme.surfaceContainerHighest
                  .withValues(alpha: isLight ? 0.58 : 0.44),
            ),
          ],
        ),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: scheme.secondary.withValues(alpha: 0.16),
            child: Text(
              participant.displayName.isEmpty
                  ? '?'
                  : participant.displayName.substring(0, 1).toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.secondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              participant.displayName,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!participant.isConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: scheme.outline.withValues(alpha: 0.14),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.42),
                ),
              ),
              child: Text(
                isRussian ? 'Не в сети' : 'Offline',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
