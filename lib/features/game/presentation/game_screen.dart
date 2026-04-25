import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:guesstogether/core/l10n/l10n.dart';
import 'package:guesstogether/core/theme/app_colors.dart';
import 'package:guesstogether/core/theme/app_spacing.dart';
import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/game/domain/game_models.dart';
import 'package:guesstogether/features/game/providers/game_providers.dart';
import 'package:guesstogether/features/home/presentation/home_screen.dart';
import 'package:guesstogether/features/lobby/providers/room_session_provider.dart';
import 'package:guesstogether/features/result/presentation/result_screen.dart';
import 'package:guesstogether/widgets/app_panel.dart';
import 'package:guesstogether/widgets/back_shortcut_scope.dart';

Color _timedFrameActiveStripeColor(ColorScheme scheme) {
  if (scheme.brightness == Brightness.light) {
    return const Color(0xFF8F6400);
  }
  return const Color(0xFFD7B34A);
}

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  static const String routePath = '/game';
  static const String routeName = 'game';

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _exitDialogOpen = false;
  final FocusNode _keyboardFocusNode = FocusNode();
  Timer? _spaceShortcutTimer;
  late final AppLifecycleListener _appLifecycleListener;

  bool get _isHost => ref.read(gameViewRoleProvider) == GameViewRole.host;

  Future<bool> _confirmExitMatch() async {
    final l10n = context.l10n;
    final bool isHost = ref.read(gameViewRoleProvider) == GameViewRole.host;
    final bool? shouldLeave = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.gameLeaveDialogTitle),
          content: Text(
            isHost ? l10n.gameLeaveDialogBodyHost : l10n.gameLeaveDialogBody,
          ),
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

  Future<void> _attemptLeaveMatch() async {
    if (_exitDialogOpen || !mounted) {
      return;
    }
    _exitDialogOpen = true;
    try {
      final bool shouldLeave = await _confirmExitMatch();
      if (shouldLeave && mounted) {
        await ref.read(gameControllerProvider.notifier).leaveMatch();
        if (mounted) {
          context.go(HomeScreen.routePath);
        }
      }
    } finally {
      _exitDialogOpen = false;
    }
  }

  void _restoreKeyboardFocus() {
    if (!mounted) {
      return;
    }
    _keyboardFocusNode.requestFocus();
  }

  void _handleAppResume() {
    unawaited(
      ref.read(gameControllerProvider.notifier).resyncAfterResume(
            isHost: _isHost,
          ),
    );
  }

  void _handleAppDetach() {
    unawaited(
      ref.read(gameControllerProvider.notifier).handleAppDetached(
            isHost: _isHost,
          ),
    );
  }

  void _runSingleSpaceShortcut() {
    if (!mounted || ref.read(gameViewRoleProvider) != GameViewRole.host) {
      return;
    }
    final GameState game = ref.read(gameControllerProvider);
    final GameController controller = ref.read(gameControllerProvider.notifier);
    if (game.phase == GamePhase.boardSelection) {
      controller.pickRandomQuestion(hostOverride: true);
      return;
    }
    if (game.phase == GamePhase.questionReveal ||
        game.phase == GamePhase.answerWindow ||
        game.phase == GamePhase.answerReveal) {
      controller.skipCurrentQuestion();
    }
  }

  KeyEventResult _handleGameKeyEvent(FocusNode node, KeyEvent event) {
    if (event.logicalKey != LogicalKeyboardKey.space) {
      return KeyEventResult.ignored;
    }
    if (ref.read(gameViewRoleProvider) != GameViewRole.host) {
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent) {
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent) {
      return KeyEventResult.handled;
    }
    if (_spaceShortcutTimer != null) {
      _spaceShortcutTimer!.cancel();
      _spaceShortcutTimer = null;
      ref.read(gameControllerProvider.notifier).skipRound();
      return KeyEventResult.handled;
    }
    _spaceShortcutTimer = Timer(const Duration(milliseconds: 260), () {
      _spaceShortcutTimer = null;
      _runSingleSpaceShortcut();
    });
    return KeyEventResult.handled;
  }

  Future<void> _showScoreDialogForPlayer(Player player) async {
    final l10n = context.l10n;
    final TextEditingController scoreController = TextEditingController(
      text: player.score.toString(),
    );
    final int? nextScore = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.gameScoreDialogTitle(player.name)),
          content: TextField(
            controller: scoreController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'-?\d*')),
            ],
            decoration: InputDecoration(
              labelText: l10n.gameScoreFieldLabel,
              hintText: l10n.gameScoreFieldHint,
            ),
          ),
          actions: <Widget>[
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.gameScoreDialogCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                int.tryParse(scoreController.text.trim()) ?? player.score,
              ),
              child: Text(l10n.gameScoreDialogSave),
            ),
          ],
        );
      },
    );
    scoreController.dispose();
    if (nextScore != null) {
      ref.read(gameControllerProvider.notifier).setPlayerScore(
            playerId: player.id,
            score: nextScore,
          );
    }
    _restoreKeyboardFocus();
  }

  Future<void> _showEditScoresDialog() async {
    final l10n = context.l10n;
    final GameState game = ref.read(gameControllerProvider);
    final Player? selectedPlayer = await showDialog<Player>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.gameScoresDialogTitle),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: game.players
                  .map(
                    (Player player) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(player.name),
                      trailing: Text(
                        '${player.score}',
                        style: Theme.of(dialogContext)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      onTap: () => Navigator.of(dialogContext).pop(player),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          actions: <Widget>[
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.gameScoreDialogCancel),
            ),
          ],
        );
      },
    );
    if (selectedPlayer != null && mounted) {
      await _showScoreDialogForPlayer(selectedPlayer);
      return;
    }
    _restoreKeyboardFocus();
  }

  bool _panelTimerActive(GameState game) {
    return game.phase == GamePhase.answerWindow;
  }

  bool _panelTimerPaused(GameState game) {
    if (game.isPaused) {
      return true;
    }
    return game.phase == GamePhase.answerWindow &&
        game.pendingAnswerPlayerId != null;
  }

  double _panelTimerProgress(GameState game) {
    if (game.phaseSecondsTotal <= 0) {
      return 1;
    }
    return (game.phaseSecondsLeft / game.phaseSecondsTotal).clamp(0, 1);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(matchRoomClosedProvider.notifier).state = false;
      ref.read(matchRoomClosedReasonProvider.notifier).state = null;
    });
    _appLifecycleListener = AppLifecycleListener(
      onResume: _handleAppResume,
      onDetach: _handleAppDetach,
    );
  }

  @override
  void dispose() {
    _spaceShortcutTimer?.cancel();
    _appLifecycleListener.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final GameState game = ref.watch(gameControllerProvider);
    final GameController controller = ref.read(gameControllerProvider.notifier);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;
    final Color questionStripeColor = isLight
        ? const Color(0xFF563600)
        : _timedFrameActiveStripeColor(scheme);
    final GameViewRole role = ref.watch(gameViewRoleProvider);
    final RoomDetails? activeRoom = ref.watch(activeRoomProvider);
    final String selectedLocalPlayerId = ref.watch(localPlayerIdProvider);
    final Map<String, bool> playerConnectionById = <String, bool>{
      for (final RoomParticipant participant
          in activeRoom?.playerParticipants ?? const <RoomParticipant>[])
        participant.id: participant.isConnected,
    };
    final GameViewRole effectiveRole = role;
    final String effectiveLocalPlayerId = game.players.any(
      (Player p) => p.id == selectedLocalPlayerId,
    )
        ? selectedLocalPlayerId
        : game.players.first.id;

    if (effectiveLocalPlayerId != selectedLocalPlayerId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref.read(localPlayerIdProvider.notifier).state = effectiveLocalPlayerId;
      });
    }

    ref.listen<GameState>(
      gameControllerProvider,
      (GameState? previous, GameState next) {
        if (previous?.isMatchEnded == false &&
            next.isMatchEnded &&
            context.mounted) {
          ref.read(matchResultSnapshotProvider.notifier).state = next;
          context.push(ResultScreen.routePath);
        }
      },
    );
    ref.listen<bool>(
      matchRoomClosedProvider,
      (bool? previous, bool next) {
        if (previous == true || !next || !context.mounted) {
          return;
        }
        if (ref.read(matchResultSnapshotProvider) != null ||
            ModalRoute.of(context)?.isCurrent != true) {
          return;
        }
        final MatchRoomClosedReason? closedReason =
            ref.read(matchRoomClosedReasonProvider);
        if (effectiveRole == GameViewRole.player &&
            closedReason == MatchRoomClosedReason.hostLeft) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.gameHostLeftMatchMessage),
            ),
          );
        }
        context.go(HomeScreen.routePath);
      },
    );

    return BackShortcutScope(
      child: Focus(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _handleGameKeyEvent,
        child: PopScope<void>(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, void _) async {
            if (didPop) {
              return;
            }
            await _attemptLeaveMatch();
          },
          child: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _CompactPlayersStrip(
                      players: game.players,
                      game: game,
                      localPlayerId: effectiveRole == GameViewRole.player
                          ? effectiveLocalPlayerId
                          : null,
                      playerConnectionById: playerConnectionById,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: _TimedFrame(
                        strokeScale: isLight ? 1.22 : 1,
                        activeColorOverride: questionStripeColor,
                        progress: _panelTimerProgress(game),
                        active: _panelTimerActive(game),
                        paused: _panelTimerPaused(game),
                        secondsLeft: game.phaseSecondsLeft,
                        secondsTotal: game.phaseSecondsTotal,
                        borderRadius: 22,
                        child: Stack(
                          children: <Widget>[
                            AppPanel(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: _MatchStageBody(
                                game: game,
                                role: effectiveRole,
                                localPlayerId: effectiveLocalPlayerId,
                                onPickQuestion: (String questionId) {
                                  controller.chooseQuestion(
                                    questionId,
                                    hostOverride:
                                        effectiveRole == GameViewRole.host,
                                  );
                                },
                              ),
                            ),
                            if (game.isPaused)
                              const Positioned(
                                right: 12,
                                bottom: 12,
                                child: _PausedCornerBadge(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _CompactControlsBar(
                      game: game,
                      role: effectiveRole,
                      localPlayerId: effectiveLocalPlayerId,
                      onStart: () => unawaited(controller.startMatch()),
                      onTogglePause: controller.togglePause,
                      onEditScores: () => unawaited(_showEditScoresDialog()),
                      onAnswer: () =>
                          controller.requestAnswer(effectiveLocalPlayerId),
                      onPass: () =>
                          controller.passQuestion(effectiveLocalPlayerId),
                      onAccept: controller.hostAcceptAnswer,
                      onReject: controller.hostRejectAnswer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PausedCornerBadge extends StatelessWidget {
  const _PausedCornerBadge();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 16,
      backgroundColor: scheme.surface.withValues(alpha: 0.94),
      child: Icon(
        Icons.pause_circle_filled_rounded,
        size: 22,
        color: scheme.primary,
      ),
    );
  }
}

class _CompactPlayersStrip extends StatelessWidget {
  const _CompactPlayersStrip({
    required this.players,
    required this.game,
    required this.localPlayerId,
    required this.playerConnectionById,
  });

  final List<Player> players;
  final GameState game;
  final String? localPlayerId;
  final Map<String, bool> playerConnectionById;

  @override
  Widget build(BuildContext context) {
    final List<Player> shownPlayers = players.take(4).toList();
    return Row(
      children: shownPlayers.map((Player player) {
        final bool isLocal = player.id == localPlayerId;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _CompactPlayerTile(
              player: player,
              isLocal: isLocal,
              game: game,
              isConnected: playerConnectionById[player.id] ?? true,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CompactPlayerTile extends StatelessWidget {
  const _CompactPlayerTile({
    required this.player,
    required this.isLocal,
    required this.game,
    required this.isConnected,
  });

  final Player player;
  final bool isLocal;
  final GameState game;
  final bool isConnected;

  bool _isAnswerPhaseForPlayer() {
    return game.phase == GamePhase.answerWindow &&
        game.pendingAnswerPlayerId == player.id;
  }

  double _activeProgress() {
    if (game.phase == GamePhase.answerWindow &&
        game.pendingAnswerPlayerId == player.id) {
      if (game.pendingAnswerSecondsTotal <= 0) {
        return 1;
      }
      return (game.pendingAnswerSecondsLeft / game.pendingAnswerSecondsTotal)
          .clamp(0, 1);
    }
    if (game.phaseSecondsTotal <= 0) {
      return 1;
    }
    final double value =
        (game.phaseSecondsLeft / game.phaseSecondsTotal).clamp(0, 1);
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;
    final Color stripeColor = _timedFrameActiveStripeColor(scheme);
    final Color border =
        scheme.outline.withValues(alpha: isLight ? 0.72 : 0.55);
    final Color localNameColor = isLocal
        ? scheme.primary.withValues(alpha: 0.98)
        : scheme.onSurface.withValues(alpha: 0.78);
    final Color scoreColor =
        (isLocal ? scheme.primary : scheme.secondary).withValues(alpha: 0.96);
    final bool isSelecting = game.phase == GamePhase.boardSelection &&
        player.id == game.currentChooserId;
    final bool isAnswering = _isAnswerPhaseForPlayer();
    final bool isCorrect = game.phase == GamePhase.answerReveal &&
        game.lastCorrectAnswerPlayerId == player.id;
    final bool showAnswerOutcome = game.phase == GamePhase.answerWindow ||
        game.phase == GamePhase.answerReveal;
    final bool isWrong =
        showAnswerOutcome && game.wrongAnswerPlayerIds.contains(player.id);
    final bool isPassed =
        showAnswerOutcome && game.passedPlayerIds.contains(player.id);
    final bool active = isSelecting || isAnswering;
    final bool showTurnAccent = isSelecting || isAnswering;
    final double progress = _activeProgress();
    final int frameSecondsLeft =
        isAnswering ? game.pendingAnswerSecondsLeft : game.phaseSecondsLeft;
    final int frameSecondsTotal =
        isAnswering ? game.pendingAnswerSecondsTotal : game.phaseSecondsTotal;
    final Color tileColor;
    if (showTurnAccent) {
      tileColor = Color.alphaBlend(
        stripeColor.withValues(alpha: isLight ? 0.24 : 0.22),
        scheme.surfaceContainerHighest.withValues(alpha: isLight ? 0.86 : 0.58),
      );
    } else if (isCorrect) {
      tileColor =
          const Color(0xFF2F8F4E).withValues(alpha: isLight ? 0.28 : 0.5);
    } else if (isWrong) {
      tileColor = scheme.error.withValues(alpha: isLight ? 0.16 : 0.22);
    } else if (isPassed) {
      tileColor = scheme.onSurface.withValues(alpha: isLight ? 0.12 : 0.16);
    } else {
      tileColor = scheme.surfaceContainerHighest
          .withValues(alpha: isLight ? 0.82 : 0.58);
    }
    final Color tileBorderColor = showTurnAccent
        ? stripeColor.withValues(alpha: isLight ? 0.92 : 0.72)
        : border;
    final List<BoxShadow> tileShadows = showTurnAccent
        ? <BoxShadow>[
            BoxShadow(
              color: stripeColor.withValues(alpha: isLight ? 0.36 : 0.28),
              blurRadius: 14,
              spreadRadius: 0.6,
            ),
          ]
        : const <BoxShadow>[];
    final Gradient? tileGradient = showTurnAccent
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              stripeColor.withValues(alpha: isLight ? 0.26 : 0.3),
              stripeColor.withValues(alpha: isLight ? 0.1 : 0.08),
            ],
          )
        : null;

    return _TimedFrame(
      progress: progress,
      active: active,
      paused: game.isPaused ||
          (game.phase == GamePhase.answerWindow &&
              game.pendingAnswerPlayerId != null &&
              game.pendingAnswerPlayerId != player.id),
      secondsLeft: frameSecondsLeft,
      secondsTotal: frameSecondsTotal,
      borderRadius: 12,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                constraints: const BoxConstraints(minHeight: 58),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tileBorderColor),
                  color: tileColor,
                  gradient: tileGradient,
                  boxShadow: tileShadows,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: localNameColor,
                        fontWeight: isLocal ? FontWeight.w800 : FontWeight.w700,
                        letterSpacing: isLocal ? 0.2 : 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _SingleLineScaleText(
                      '${player.score}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const <ui.FontFeature>[
                          ui.FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!isConnected)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.96),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.error.withValues(alpha: 0.88),
                  ),
                ),
                child: Icon(
                  Icons.link_off_rounded,
                  size: 11,
                  color: scheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MatchStageBody extends StatelessWidget {
  const _MatchStageBody({
    required this.game,
    required this.role,
    required this.localPlayerId,
    required this.onPickQuestion,
  });

  final GameState game;
  final GameViewRole role;
  final String localPlayerId;
  final ValueChanged<String> onPickQuestion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (game.phase == GamePhase.waitingForHost) {
      return Center(
        child: Text(l10n.gameHostShouldStartMatch),
      );
    }
    if (game.phase == GamePhase.finished) {
      return Center(
        child: Text(l10n.gameMatchFinishedBody),
      );
    }

    if (game.phase == GamePhase.boardSelection ||
        game.phase == GamePhase.questionReveal) {
      final bool canPick = role == GameViewRole.host ||
          (role == GameViewRole.player &&
              localPlayerId == game.currentChooserId);
      return _JeopardyBoard(
        questions: game.roundBoardQuestions.toList(growable: false),
        enabled:
            game.phase == GamePhase.boardSelection && canPick && !game.isPaused,
        highlightedQuestionId: game.phase == GamePhase.questionReveal
            ? game.currentQuestion?.id
            : null,
        onPickQuestion: onPickQuestion,
      );
    }

    return _QuestionView(game: game, role: role);
  }
}

class _JeopardyBoard extends StatelessWidget {
  const _JeopardyBoard({
    required this.questions,
    required this.enabled,
    required this.highlightedQuestionId,
    required this.onPickQuestion,
  });

  final List<Question> questions;
  final bool enabled;
  final String? highlightedQuestionId;
  final ValueChanged<String> onPickQuestion;

  @override
  Widget build(BuildContext context) {
    final List<String> categories = questions
        .map((Question question) => question.category)
        .toSet()
        .toList();
    final List<int> values = questions
        .map((Question question) => question.value)
        .toSet()
        .toList()
      ..sort();

    Question? findQuestion(String category, int value) {
      for (final Question question in questions) {
        if (question.category == category && question.value == value) {
          return question;
        }
      }
      return null;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double topicColumnWidth = math.max(
          88,
          math.min(132, constraints.maxWidth * 0.28),
        );

        return Column(
          children: <Widget>[
            for (final String category in categories)
              Expanded(
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: topicColumnWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 3,
                        ),
                        child: _BoardHeaderCell(title: category),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: values.map((int value) {
                          final Question? question =
                              findQuestion(category, value);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                                vertical: 3,
                              ),
                              child: _BoardQuestionCell(
                                question: question,
                                enabled: enabled,
                                highlighted:
                                    question?.id == highlightedQuestionId,
                                onTap: () {
                                  if (question != null) {
                                    onPickQuestion(question.id);
                                  }
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BoardHeaderCell extends StatelessWidget {
  const _BoardHeaderCell({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isLight ? const Color(0xFF3D6FB7) : const Color(0xFF1E3C70),
        border: Border.all(
          color: isLight
              ? scheme.primary.withValues(alpha: 0.34)
              : Colors.white.withValues(alpha: 0.14),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BoardQuestionCell extends StatelessWidget {
  const _BoardQuestionCell({
    required this.question,
    required this.enabled,
    required this.highlighted,
    required this.onTap,
  });

  final Question? question;
  final bool enabled;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    final ColorScheme scheme = theme.colorScheme;
    final Color highlightedBackground =
        isLight ? const Color(0xFFFFE18A) : const Color(0xFF245785);
    final Color highlightedBorder =
        isLight ? const Color(0xFFAD6E00) : AppColors.focusRing;
    final Color highlightedShadow =
        isLight ? const Color(0xFFE7A500) : AppColors.focusRing;
    final Color highlightedText =
        isLight ? const Color(0xFF4C2A00) : const Color(0xFFF3FBFF);
    final bool isUsed = question == null || (question!.used && !highlighted);
    final bool canTap = enabled && !isUsed;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: canTap ? onTap : null,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: highlighted
              ? highlightedBackground
              : isUsed
                  ? (isLight
                      ? const Color(0xFFB8C9E7)
                      : const Color(0xFF0F2445))
                  : (isLight
                      ? const Color(0xFF3F74BE)
                      : const Color(0xFF1D4A8A)),
          border: Border.all(
            color: highlighted
                ? highlightedBorder
                : isUsed
                    ? (isLight
                        ? scheme.outline.withValues(alpha: 0.32)
                        : Colors.transparent)
                    : Colors.white.withValues(alpha: canTap ? 0.56 : 0.24),
          ),
          boxShadow: highlighted
              ? <BoxShadow>[
                  BoxShadow(
                    color: highlightedShadow.withValues(
                        alpha: isLight ? 0.34 : 0.28),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: _SingleLineScaleText(
              isUsed ? '' : '${question!.value}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: highlighted
                    ? highlightedText
                    : (isLight
                        ? const Color(0xFFFFEDAD)
                        : const Color(0xFFF7D66A)),
                fontWeight: FontWeight.w800,
                fontFeatures: const <ui.FontFeature>[
                  ui.FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SingleLineScaleText extends StatelessWidget {
  const _SingleLineScaleText(
    this.text, {
    this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: style,
        ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.game,
    required this.role,
  });

  final GameState game;
  final GameViewRole role;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;
    final Question? question = game.currentQuestion;
    if (question == null) {
      return Center(child: Text(l10n.gameNoActiveClueBody));
    }

    final bool revealAnswer = game.phase == GamePhase.answerReveal;
    final bool animateQuestion = game.phase == GamePhase.answerWindow &&
        !game.isPaused &&
        game.pendingAnswerPlayerId == null;
    final bool showHostAnswer = role == GameViewRole.host && !revealAnswer;
    final String infoText = revealAnswer
        ? l10n.gameCorrectAnswerLabel
        : '${question.category} - ${question.value}';

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            if (isLight) ...<Color>[
              const Color(0xFFDCE8FF),
              const Color(0xFFC9DBFF),
            ] else ...<Color>[
              const Color(0xFF162546),
              const Color(0xFF0F1D39),
            ],
          ],
        ),
        border: Border.all(
          color: isLight
              ? scheme.primary.withValues(alpha: 0.32)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            infoText,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: revealAnswer
                  ? (isLight
                      ? const Color(0xFF1F7A3D)
                      : const Color(0xFF9EF3B2))
                  : (isLight
                      ? scheme.onSurfaceVariant
                      : Colors.white.withValues(alpha: 0.7)),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Center(
              child: revealAnswer
                  ? Text(
                      question.answer,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: isLight
                            ? const Color(0xFF1F7A3D)
                            : const Color(0xFF9EF3B2),
                        fontWeight: FontWeight.w700,
                        height: 1.28,
                      ),
                    )
                  : _TypewriterQuestion(
                      text: question.text,
                      animate: animateQuestion,
                      paused: game.isPaused,
                      color: isLight ? scheme.onSurface : Colors.white,
                    ),
            ),
          ),
          if (showHostAnswer) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              question.answer,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isLight ? const Color(0xFF1F7A3D) : const Color(0xFF9EF3B2),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypewriterQuestion extends StatefulWidget {
  const _TypewriterQuestion({
    required this.text,
    required this.animate,
    required this.paused,
    required this.color,
  });

  final String text;
  final bool animate;
  final bool paused;
  final Color color;

  @override
  State<_TypewriterQuestion> createState() => _TypewriterQuestionState();
}

class _TypewriterQuestionState extends State<_TypewriterQuestion> {
  Timer? _timer;
  int _visibleChars = 0;

  @override
  void initState() {
    super.initState();
    _initializeForNewText();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant _TypewriterQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _initializeForNewText();
    }
    _syncTicker();
  }

  void _initializeForNewText() {
    setState(() => _visibleChars = 0);
  }

  void _syncTicker() {
    if (widget.paused || !widget.animate) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (_visibleChars >= widget.text.length) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (_timer != null) {
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 44), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        _timer = null;
        return;
      }
      if (widget.paused || !widget.animate) {
        timer.cancel();
        _timer = null;
        return;
      }
      if (_visibleChars >= widget.text.length) {
        timer.cancel();
        _timer = null;
        return;
      }
      setState(() {
        _visibleChars = (_visibleChars + 1).clamp(0, widget.text.length);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String visible = widget.text.substring(0, _visibleChars);
    return Text(
      visible,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: widget.color,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
    );
  }
}

class _CompactControlsBar extends StatelessWidget {
  const _CompactControlsBar({
    required this.game,
    required this.role,
    required this.localPlayerId,
    required this.onStart,
    required this.onTogglePause,
    required this.onEditScores,
    required this.onAnswer,
    required this.onPass,
    required this.onAccept,
    required this.onReject,
  });

  final GameState game;
  final GameViewRole role;
  final String localPlayerId;
  final VoidCallback onStart;
  final VoidCallback onTogglePause;
  final VoidCallback onEditScores;
  final VoidCallback onAnswer;
  final VoidCallback onPass;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    if (role == GameViewRole.host) {
      return _HostCompactControls(
        game: game,
        onStart: onStart,
        onTogglePause: onTogglePause,
        onEditScores: onEditScores,
        onAccept: onAccept,
        onReject: onReject,
      );
    }
    return _PlayerCompactControls(
      game: game,
      localPlayerId: localPlayerId,
      onAnswer: onAnswer,
      onPass: onPass,
    );
  }
}

class _HostCompactControls extends StatelessWidget {
  const _HostCompactControls({
    required this.game,
    required this.onStart,
    required this.onTogglePause,
    required this.onEditScores,
    required this.onAccept,
    required this.onReject,
  });

  final GameState game;
  final VoidCallback onStart;
  final VoidCallback onTogglePause;
  final VoidCallback onEditScores;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    final Color disabledActionForeground =
        theme.colorScheme.onSurface.withValues(alpha: isLight ? 0.72 : 0.78);
    final bool pending = game.pendingAnswerPlayerId != null &&
        game.phase == GamePhase.answerWindow;
    final bool waiting = game.phase == GamePhase.waitingForHost;
    final bool paused = game.isPaused;
    final bool canModerate = pending && !game.isMatchEnded;
    final bool canTogglePauseOrStart = !game.isMatchEnded;
    final bool canEditScores = !waiting && !game.isMatchEnded;
    final ButtonStyle hostMainStyle = FilledButton.styleFrom(
      foregroundColor: Colors.black,
      disabledForegroundColor: Colors.black.withValues(alpha: 0.58),
    );
    final ButtonStyle editScoresStyle = hostMainStyle;
    final ButtonStyle acceptStyle = FilledButton.styleFrom(
      backgroundColor:
          isLight ? const Color(0xFF2A8346) : const Color(0xFF2F8F4E),
      foregroundColor: Colors.white,
      disabledBackgroundColor:
          (isLight ? const Color(0xFF2A8346) : const Color(0xFF2F8F4E))
              .withValues(alpha: 0.32),
      disabledForegroundColor: disabledActionForeground,
    );
    final ButtonStyle rejectStyle = FilledButton.styleFrom(
      backgroundColor: const Color(0xFFA93E3E),
      foregroundColor: const Color(0xFFFFEBEB),
      disabledBackgroundColor: const Color(0xFFA93E3E).withValues(alpha: 0.34),
      disabledForegroundColor: disabledActionForeground,
    );

    return AppPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _AdaptiveButtonPair(
            leading: _CompactFilledButton(
              style: hostMainStyle,
              onPressed: canTogglePauseOrStart
                  ? (waiting ? onStart : onTogglePause)
                  : null,
              icon: waiting
                  ? Icons.play_arrow_rounded
                  : (paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
              label: waiting
                  ? l10n.gameHostStartCta
                  : (paused ? l10n.gameHostUnpauseCta : l10n.gameHostPauseCta),
            ),
            trailing: _CompactFilledButton(
              style: editScoresStyle,
              onPressed: canEditScores ? onEditScores : null,
              icon: Icons.tune_rounded,
              label: l10n.gameHostScoresCta,
            ),
          ),
          const SizedBox(height: 8),
          _AdaptiveButtonPair(
            leading: _CompactFilledButton(
              style: acceptStyle,
              onPressed: canModerate ? onAccept : null,
              icon: Icons.check_rounded,
              label: l10n.gameHostAcceptCta,
            ),
            trailing: _CompactFilledButton(
              style: rejectStyle,
              onPressed: canModerate ? onReject : null,
              icon: Icons.close_rounded,
              label: l10n.gameHostRejectCta,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerCompactControls extends StatelessWidget {
  const _PlayerCompactControls({
    required this.game,
    required this.localPlayerId,
    required this.onAnswer,
    required this.onPass,
  });

  final GameState game;
  final String localPlayerId;
  final VoidCallback onAnswer;
  final VoidCallback onPass;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    final Color disabledActionForeground =
        theme.colorScheme.onSurface.withValues(alpha: isLight ? 0.72 : 0.78);
    final bool canAnswer = game.phase == GamePhase.answerWindow &&
        !game.isPaused &&
        game.pendingAnswerPlayerId == null &&
        !game.passedPlayerIds.contains(localPlayerId) &&
        !game.wrongAnswerPlayerIds.contains(localPlayerId);
    final ButtonStyle answerStyle = FilledButton.styleFrom(
      backgroundColor:
          isLight ? const Color(0xFF2A8346) : const Color(0xFF2F8F4E),
      foregroundColor: Colors.white,
      disabledBackgroundColor:
          (isLight ? const Color(0xFF2A8346) : const Color(0xFF2F8F4E))
              .withValues(alpha: 0.36),
      disabledForegroundColor: disabledActionForeground,
    );
    final ButtonStyle passStyle = FilledButton.styleFrom(
      backgroundColor:
          isLight ? const Color(0xFF5F6774) : const Color(0xFF6F7681),
      foregroundColor: Colors.white,
      disabledBackgroundColor:
          (isLight ? const Color(0xFF5F6774) : const Color(0xFF6F7681))
              .withValues(alpha: 0.34),
      disabledForegroundColor: disabledActionForeground,
    );

    return AppPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: _AdaptiveButtonPair(
        leading: _CompactFilledButton(
          style: answerStyle,
          onPressed: canAnswer ? onAnswer : null,
          icon: Icons.check_rounded,
          label: l10n.gameAnswerCta,
        ),
        trailing: _CompactFilledButton(
          style: passStyle,
          onPressed: canAnswer ? onPass : null,
          icon: Icons.close_rounded,
          label: l10n.gamePassCta,
        ),
      ),
    );
  }
}

class _CompactFilledButton extends StatelessWidget {
  const _CompactFilledButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.style,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final ThemeData theme = Theme.of(context);
        final bool compact = constraints.maxWidth < 118;
        final bool ultraCompact = constraints.maxWidth < 102;
        final double iconSize = ultraCompact ? 15 : (compact ? 16 : 18);
        final double spacing = ultraCompact ? 3 : (compact ? 4 : 6);
        final EdgeInsetsGeometry padding = EdgeInsets.symmetric(
          horizontal: ultraCompact ? 6 : 8,
          vertical: ultraCompact ? 8 : 10,
        );
        final Set<WidgetState> states = onPressed == null
            ? const <WidgetState>{WidgetState.disabled}
            : const <WidgetState>{};
        final ButtonStyle mergedStyle =
            theme.filledButtonTheme.style?.merge(style) ??
                style ??
                const ButtonStyle();
        final ButtonStyle effectiveStyle = mergedStyle.copyWith(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AppSpacing.tapTargetMin),
          ),
          padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(padding),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
        final Color contentColor =
            effectiveStyle.foregroundColor?.resolve(states) ??
                (onPressed == null
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                    : theme.colorScheme.onPrimary);
        final TextStyle? labelStyle = theme.textTheme.labelLarge?.copyWith(
          fontSize: ultraCompact ? 11.5 : (compact ? 12.5 : null),
          fontWeight: FontWeight.w700,
          height: 1,
          color: contentColor,
        );

        return FilledButton(
          style: effectiveStyle,
          onPressed: onPressed,
          child: SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, size: iconSize, color: contentColor),
                  SizedBox(width: spacing),
                  Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: labelStyle,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AdaptiveButtonPair extends StatelessWidget {
  const _AdaptiveButtonPair({
    required this.leading,
    required this.trailing,
  });

  final Widget leading;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: leading),
        const SizedBox(width: 8),
        Expanded(child: trailing),
      ],
    );
  }
}

class _TimedFrame extends StatefulWidget {
  const _TimedFrame({
    required this.progress,
    required this.active,
    required this.paused,
    required this.secondsLeft,
    required this.secondsTotal,
    required this.borderRadius,
    required this.child,
    this.strokeScale = 1,
    this.activeColorOverride,
  });

  final double progress;
  final bool active;
  final bool paused;
  final int secondsLeft;
  final int secondsTotal;
  final double borderRadius;
  final Widget child;
  final double strokeScale;
  final Color? activeColorOverride;

  @override
  State<_TimedFrame> createState() => _TimedFrameState();
}

class _TimedFrameState extends State<_TimedFrame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  DateTime? _anchorAt;
  double _anchorSecondsLeft = 0;
  double _display = 1;

  bool get _canRun =>
      widget.active && !widget.paused && widget.secondsTotal > 0;

  double get _safeTotal => math.max(1, widget.secondsTotal).toDouble();

  double _computeDisplayNow() {
    if (_anchorAt == null || widget.secondsTotal <= 0) {
      return widget.progress.clamp(0, 1);
    }
    final double elapsed =
        DateTime.now().difference(_anchorAt!).inMicroseconds / 1000000;
    final double secondsLeft =
        (_anchorSecondsLeft - elapsed).clamp(0, _safeTotal);
    return (secondsLeft / _safeTotal).clamp(0, 1);
  }

  void _setDisplay(double value) {
    final double clamped = value.clamp(0, 1);
    if ((clamped - _display).abs() < 0.0001) {
      return;
    }
    setState(() {
      _display = clamped;
    });
  }

  void _anchorTo(double secondsLeft, {bool snapToAnchor = false}) {
    _anchorSecondsLeft = secondsLeft.clamp(0, _safeTotal);
    _anchorAt = DateTime.now();
    if (snapToAnchor) {
      _setDisplay(_anchorSecondsLeft / _safeTotal);
    }
  }

  void _syncAnchorFromState(double secondsLeft, {bool snapToAnchor = false}) {
    final double currentSeconds = (_display * _safeTotal).clamp(0, _safeTotal);
    final double targetSeconds = secondsLeft.clamp(0, _safeTotal);
    final double monotonicSeconds = math.min(currentSeconds, targetSeconds);
    _anchorTo(monotonicSeconds, snapToAnchor: snapToAnchor);
  }

  void _startTickerIfNeeded() {
    if (_canRun && !_ticker.isActive) {
      _ticker.start();
    }
  }

  void _stopTicker() {
    if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    if (!_canRun) {
      return;
    }
    _setDisplay(_computeDisplayNow());
  }

  @override
  void initState() {
    super.initState();
    _display = widget.progress.clamp(0, 1);
    _ticker = createTicker(_onTick);
    _anchorTo(widget.secondsLeft.toDouble());
    _startTickerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _TimedFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    final double target = widget.progress.clamp(0, 1);
    final bool enteringPaused = !oldWidget.paused && widget.paused;
    final bool leavingPaused = oldWidget.paused && !widget.paused;
    final bool tickUpdated = oldWidget.secondsLeft != widget.secondsLeft;
    final bool totalUpdated = oldWidget.secondsTotal != widget.secondsTotal;
    final bool restarted = target > oldWidget.progress + 0.0001;

    if (!widget.active || widget.secondsTotal <= 0) {
      _stopTicker();
      _anchorAt = null;
      _setDisplay(target);
      return;
    }

    if (enteringPaused) {
      _setDisplay(_computeDisplayNow());
      _stopTicker();
      _anchorTo(_display * _safeTotal);
      return;
    }

    if (widget.paused) {
      _stopTicker();
      return;
    }

    if (leavingPaused) {
      _syncAnchorFromState(widget.secondsLeft.toDouble());
      _startTickerIfNeeded();
      return;
    }

    if (totalUpdated || restarted) {
      _anchorTo(widget.secondsLeft.toDouble(), snapToAnchor: true);
      _startTickerIfNeeded();
      return;
    }

    if (tickUpdated) {
      _syncAnchorFromState(widget.secondsLeft.toDouble());
      _startTickerIfNeeded();
      return;
    }

    _startTickerIfNeeded();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isLight = scheme.brightness == Brightness.light;
    return CustomPaint(
      painter: _TimedFramePainter(
        progress: _display,
        active: widget.active,
        borderRadius: widget.borderRadius,
        activeColor:
            widget.activeColorOverride ?? _timedFrameActiveStripeColor(scheme),
        idleColor: scheme.outline.withValues(alpha: isLight ? 0.68 : 0.45),
        activeStrokeWidth: 3.8 * widget.strokeScale,
        idleStrokeWidth: 3.2 * widget.strokeScale,
      ),
      child: widget.child,
    );
  }
}

class _TimedFramePainter extends CustomPainter {
  const _TimedFramePainter({
    required this.progress,
    required this.active,
    required this.borderRadius,
    required this.activeColor,
    required this.idleColor,
    required this.activeStrokeWidth,
    required this.idleStrokeWidth,
  });

  final double progress;
  final bool active;
  final double borderRadius;
  final Color activeColor;
  final Color idleColor;
  final double activeStrokeWidth;
  final double idleStrokeWidth;

  Path _clockwiseBorderPath(Rect rect, double radius) {
    final double r = math.max(
      0,
      math.min(radius, math.min(rect.width, rect.height) / 2),
    );
    final double left = rect.left;
    final double top = rect.top;
    final double right = rect.right;
    final double bottom = rect.bottom;
    final double topCenterX = (left + right) / 2;

    final Path path = Path()..moveTo(topCenterX, top);
    path.lineTo(right - r, top);
    if (r > 0) {
      path.arcToPoint(
        Offset(right, top + r),
        radius: Radius.circular(r),
        clockwise: true,
      );
    }
    path.lineTo(right, bottom - r);
    if (r > 0) {
      path.arcToPoint(
        Offset(right - r, bottom),
        radius: Radius.circular(r),
        clockwise: true,
      );
    }
    path.lineTo(left + r, bottom);
    if (r > 0) {
      path.arcToPoint(
        Offset(left, bottom - r),
        radius: Radius.circular(r),
        clockwise: true,
      );
    }
    path.lineTo(left, top + r);
    if (r > 0) {
      path.arcToPoint(
        Offset(left + r, top),
        radius: Radius.circular(r),
        clockwise: true,
      );
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double pathInset = activeStrokeWidth / 2;
    final Rect rect = Offset.zero & size;
    final Path borderPath = _clockwiseBorderPath(
      rect.deflate(pathInset),
      borderRadius,
    );

    final Paint idlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = idleStrokeWidth
      ..color = idleColor;
    canvas.drawPath(borderPath, idlePaint);

    final double clamped = progress.clamp(0, 1);
    if (!active || clamped <= 0) {
      return;
    }

    final Paint activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = activeStrokeWidth
      ..strokeCap = StrokeCap.butt
      ..color = activeColor;

    final Iterable<ui.PathMetric> metrics = borderPath.computeMetrics();
    for (final ui.PathMetric metric in metrics) {
      final double start = metric.length * (1 - clamped);
      final Path extract = metric.extractPath(start, metric.length);
      canvas.drawPath(extract, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimedFramePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.active != active ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.idleColor != idleColor ||
        oldDelegate.activeStrokeWidth != activeStrokeWidth ||
        oldDelegate.idleStrokeWidth != idleStrokeWidth;
  }
}
