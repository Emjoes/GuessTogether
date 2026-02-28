import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:guesstogether/core/l10n/l10n.dart';
import 'package:guesstogether/core/theme/app_spacing.dart';
import 'package:guesstogether/features/game/presentation/game_screen.dart';
import 'package:guesstogether/features/lobby/providers/join_room_provider.dart';
import 'package:guesstogether/widgets/app_panel.dart';
import 'package:guesstogether/widgets/back_shortcut_scope.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  static const String routePath = '/join-room';
  static const String routeName = 'joinRoom';

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  String _searchQuery = '';

  Future<String?> _requestPassword(BuildContext context) async {
    final l10n = context.l10n;
    String password = '';
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.joinRoomPasswordDialogTitle),
          content: TextField(
            autofocus: true,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.createRoomPasswordLabel,
              hintText: l10n.joinRoomPasswordDialogHint,
            ),
            onChanged: (String value) {
              password = value;
            },
            onSubmitted: (String value) {
              Navigator.of(dialogContext).pop(value.trim());
            },
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                MaterialLocalizations.of(dialogContext).cancelButtonLabel,
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(password.trim()),
              child: Text(l10n.joinRoomPasswordJoinCta),
            ),
          ],
        );
      },
    );
    return result;
  }

  Future<void> _handleJoin(LobbyRoom room) async {
    final JoinRoomController controller =
        ref.read(joinRoomControllerProvider.notifier);
    controller.clearError();
    String? password;
    if (room.requiresPassword) {
      password = await _requestPassword(context);
      if (password == null) {
        return;
      }
    }

    final JoinLobbyResult result = await controller.joinLobby(
      room,
      password: password,
    );
    if (!mounted) {
      return;
    }
    switch (result) {
      case JoinLobbyResult.success:
        context.push(GameScreen.routePath);
      case JoinLobbyResult.invalidPassword:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.joinRoomErrorWrongPassword)),
        );
      case JoinLobbyResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.joinRoomErrorInvalid)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final JoinRoomState state = ref.watch(joinRoomControllerProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;
    final bool isLight = theme.brightness == Brightness.light;
    final String normalizedQuery = _searchQuery.trim().toLowerCase();
    final List<LobbyRoom> rooms = normalizedQuery.isEmpty
        ? state.rooms
        : state.rooms
            .where((LobbyRoom room) =>
                room.name.toLowerCase().contains(normalizedQuery))
            .toList();

    final Color panelBase =
        scheme.surfaceContainerHighest.withValues(alpha: isLight ? 0.76 : 0.58);
    final Gradient setupGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color.alphaBlend(
          Colors.white.withValues(alpha: isLight ? 0.16 : 0.08),
          panelBase,
        ),
        Color.alphaBlend(
          scheme.primary.withValues(alpha: isLight ? 0.08 : 0.11),
          panelBase,
        ),
        Color.alphaBlend(
          scheme.secondary.withValues(alpha: isLight ? 0.05 : 0.08),
          panelBase,
        ),
      ],
    );

    return BackShortcutScope(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.joinRoomTitle)),
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
                  gradient: setupGradient,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      TextField(
                        decoration: InputDecoration(
                          labelText: l10n.joinRoomSearchHint,
                          hintText: l10n.joinRoomSearchHintText,
                          prefixIcon: const Icon(Icons.search_rounded),
                        ),
                        onChanged: (String value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppPanel(
                  gradient: setupGradient,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        l10n.joinRoomActiveLobbies,
                        style: text.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (rooms.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Text(
                            l10n.joinRoomNoLobbies,
                            textAlign: TextAlign.center,
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.92),
                            ),
                          ),
                        )
                      else
                        Column(
                          children:
                              List<Widget>.generate(rooms.length, (int index) {
                            final LobbyRoom room = rooms[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == rooms.length - 1
                                    ? 0
                                    : AppSpacing.sm,
                              ),
                              child: _LobbyRow(
                                room: room,
                                isLoading: state.isLoading &&
                                    state.joiningRoomId == room.id,
                                onTap: () => _handleJoin(room),
                              ),
                            );
                          }),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LobbyRow extends StatefulWidget {
  const _LobbyRow({
    required this.room,
    required this.isLoading,
    required this.onTap,
  });

  final LobbyRoom room;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  State<_LobbyRow> createState() => _LobbyRowState();
}

class _LobbyRowState extends State<_LobbyRow> {
  bool _hovered = false;
  bool _pressed = false;

  void _setHovered(bool value) {
    if (_hovered == value) {
      return;
    }
    setState(() => _hovered = value);
  }

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final l10n = context.l10n;
    final bool isLight = theme.brightness == Brightness.light;
    final double interaction = _pressed ? 0.2 : (_hovered ? 0.12 : 0.06);
    final Color base =
        scheme.surfaceContainerHighest.withValues(alpha: isLight ? 0.66 : 0.44);
    final Color topColor = Color.alphaBlend(
      Colors.white.withValues(alpha: isLight ? 0.16 : 0.08),
      base,
    );
    final Color bottomColor = Color.alphaBlend(
      scheme.primary.withValues(alpha: interaction),
      base,
    );
    final Color borderColor =
        scheme.outline.withValues(alpha: _hovered ? 0.56 : 0.42);

    return MouseRegion(
      cursor: widget.isLoading
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.99 : (_hovered ? 1.01 : 1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          constraints:
              const BoxConstraints(minHeight: AppSpacing.tapTargetMin + 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[topColor, bottomColor],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.09 : 0.22),
                blurRadius: _hovered ? 16 : 10,
                offset: Offset(0, _hovered ? 9 : 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.isLoading ? null : widget.onTap,
              onHover: widget.isLoading ? null : _setHovered,
              onHighlightChanged: widget.isLoading ? null : _setPressed,
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return scheme.primary.withValues(alpha: isLight ? 0.14 : 0.2);
                }
                if (states.contains(WidgetState.hovered)) {
                  return scheme.primary
                      .withValues(alpha: isLight ? 0.06 : 0.12);
                }
                return Colors.transparent;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 10,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 5,
                      child: Text(
                        widget.room.name,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _IconLabelCell(
                        icon: Icons.groups_rounded,
                        label: l10n.joinRoomPlayersCount(
                          widget.room.currentPlayers,
                          widget.room.maxPlayers,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: widget.room.type == LobbyType.duel
                            ? _CrossedSwordsIcon(
                                size: 17,
                                color: scheme.primary.withValues(alpha: 0.95),
                              )
                            : Icon(
                                Icons.diversity_3_rounded,
                                size: 18,
                                color: scheme.primary.withValues(alpha: 0.95),
                              ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Icon(
                          widget.room.requiresPassword
                              ? Icons.lock_rounded
                              : Icons.lock_open_rounded,
                          size: 18,
                          color: widget.room.requiresPassword
                              ? scheme.tertiary.withValues(alpha: 0.95)
                              : scheme.secondary.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 24,
                      child: Center(
                        child: widget.isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      scheme.primary),
                                ),
                              )
                            : Icon(
                                Icons.chevron_right_rounded,
                                color: scheme.onSurfaceVariant
                                    .withValues(alpha: 0.84),
                              ),
                      ),
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

class _IconLabelCell extends StatelessWidget {
  const _IconLabelCell({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: scheme.primary.withValues(alpha: 0.92)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _CrossedSwordsIcon extends StatelessWidget {
  const _CrossedSwordsIcon({
    required this.color,
    this.size = 20,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CrossedSwordsPainter(color),
    );
  }
}

class _CrossedSwordsPainter extends CustomPainter {
  const _CrossedSwordsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double unit = size.shortestSide;
    final Paint bladePaint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;
    final Paint handlePaint = Paint()
      ..color = Color.alphaBlend(Colors.black.withValues(alpha: 0.24), color)
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    _drawSword(canvas, center, unit, 0.82, bladePaint, handlePaint);
    _drawSword(canvas, center, unit, -0.82, bladePaint, handlePaint);
  }

  void _drawSword(
    Canvas canvas,
    Offset center,
    double unit,
    double angle,
    Paint bladePaint,
    Paint handlePaint,
  ) {
    final double bladeWidth = unit * 0.16;
    final double bladeLength = unit * 0.42;
    final double tipLength = unit * 0.14;
    final double guardWidth = unit * 0.4;
    final double guardHeight = unit * 0.07;
    final double gripWidth = unit * 0.1;
    final double gripLength = unit * 0.2;
    final double pommelRadius = unit * 0.06;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final Path bladePath = Path()
      ..moveTo(-bladeWidth / 2, 0)
      ..lineTo(-bladeWidth / 2, -bladeLength)
      ..lineTo(0, -bladeLength - tipLength)
      ..lineTo(bladeWidth / 2, -bladeLength)
      ..lineTo(bladeWidth / 2, 0)
      ..close();
    canvas.drawPath(bladePath, bladePaint);

    final RRect guard = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: guardWidth,
        height: guardHeight,
      ),
      Radius.circular(guardHeight / 2),
    );
    canvas.drawRRect(guard, handlePaint);

    final RRect grip = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, guardHeight / 2 + gripLength / 2 + unit * 0.01),
        width: gripWidth,
        height: gripLength,
      ),
      Radius.circular(gripWidth / 2),
    );
    canvas.drawRRect(grip, handlePaint);

    canvas.drawCircle(
      Offset(0, guardHeight / 2 + gripLength + pommelRadius * 0.85),
      pommelRadius,
      handlePaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CrossedSwordsPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
