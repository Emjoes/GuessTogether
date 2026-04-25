import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:guesstogether/core/l10n/l10n.dart';
import 'package:guesstogether/core/theme/app_spacing.dart';
import 'package:guesstogether/data/api/app_backend_api.dart';
import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/lobby/providers/create_room_provider.dart';
import 'package:guesstogether/features/lobby/presentation/waiting_room_screen.dart';
import 'package:guesstogether/widgets/app_panel.dart';
import 'package:guesstogether/widgets/back_shortcut_scope.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  static const String routePath = '/create-room';
  static const String routeName = 'createRoom';

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(createRoomControllerProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final CreateRoomState state = ref.watch(createRoomControllerProvider);
    final CreateRoomController controller =
        ref.read(createRoomControllerProvider.notifier);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;
    final bool isLight = theme.brightness == Brightness.light;
    final bool isRussian =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ru';
    final String createRoomErrorText = isRussian
        ? 'Не удалось создать комнату.'
        : 'Failed to create the room.';
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
        appBar: AppBar(title: Text(l10n.createRoomTitle)),
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
                      Text(
                        l10n.createRoomDetailsLabel,
                        style: text.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        decoration: InputDecoration(
                          labelText: l10n.createRoomNameLabel,
                          hintText: l10n.createRoomNameHint,
                        ),
                        onChanged: controller.setName,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        decoration: InputDecoration(
                          labelText: l10n.createRoomPasswordLabel,
                          hintText: l10n.createRoomPasswordHint,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: controller.setPassword,
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
                        l10n.createRoomModeLabel,
                        style: text.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Column(
                        children: <Widget>[
                          _ModeButton(
                            selected: state.mode == RoomMode.multiplayer,
                            enabled: true,
                            iconBuilder: (Color color) => Icon(
                              Icons.diversity_3_rounded,
                              size: 20,
                              color: color,
                            ),
                            label: l10n.createRoomModeMultiplayer,
                            onPressed: () =>
                                controller.setMode(RoomMode.multiplayer),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _ModeButton(
                            selected: state.mode == RoomMode.duel,
                            enabled: false,
                            iconBuilder: (Color color) =>
                                _CrossedSwordsIcon(size: 20, color: color),
                            label:
                                '${l10n.createRoomModeDuel} (${l10n.createRoomPackageSoon})',
                            onPressed: () => controller.setMode(RoomMode.duel),
                          ),
                        ],
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
                        l10n.createRoomPackageLabel,
                        style: text.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _PackagePickerField(
                        fileName: state.packageFileName,
                        onPick: () {},
                        enabled: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _CreateButton(
                  isLoading: state.isLoading,
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          try {
                            final RoomSummary room =
                                await controller.createRoom();
                            if (context.mounted) {
                              context.push(
                                WaitingRoomScreen.routeLocation(room.id),
                              );
                            }
                          } on BackendException catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    error.message.isEmpty
                                        ? createRoomErrorText
                                        : error.message,
                                  ),
                                ),
                              );
                            }
                          } on Exception {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(createRoomErrorText),
                                ),
                              );
                            }
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PackagePickerField extends StatefulWidget {
  const _PackagePickerField({
    required this.fileName,
    required this.onPick,
    required this.enabled,
  });

  final String fileName;
  final VoidCallback onPick;
  final bool enabled;

  @override
  State<_PackagePickerField> createState() => _PackagePickerFieldState();
}

class _PackagePickerFieldState extends State<_PackagePickerField> {
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
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;
    final bool isInteractive = widget.enabled;
    final double interaction =
        !isInteractive ? 0 : (_pressed ? 0.2 : (_hovered ? 0.12 : 0.06));
    final Color base =
        scheme.surfaceContainerHighest.withValues(alpha: isLight ? 0.66 : 0.44);
    final Color topColor = Color.alphaBlend(
      Colors.white
          .withValues(alpha: isInteractive ? (isLight ? 0.16 : 0.08) : 0.04),
      base,
    );
    final Color bottomColor = Color.alphaBlend(
      scheme.primary.withValues(alpha: isInteractive ? interaction : 0.02),
      base,
    );
    final Color borderColor = scheme.outline.withValues(
      alpha: isInteractive ? (_hovered ? 0.56 : 0.42) : 0.28,
    );

    return MouseRegion(
      cursor:
          isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        scale: !isInteractive ? 1 : (_pressed ? 0.99 : (_hovered ? 1.01 : 1)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          width: double.infinity,
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
              onTap: isInteractive ? widget.onPick : null,
              onHover: isInteractive ? _setHovered : null,
              onHighlightChanged: isInteractive ? _setPressed : null,
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (!isInteractive) {
                  return Colors.transparent;
                }
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
                    Icon(
                      Icons.file_present_rounded,
                      size: 20,
                      color: isInteractive
                          ? scheme.primary.withValues(alpha: 0.92)
                          : scheme.onSurfaceVariant.withValues(alpha: 0.72),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${l10n.createRoomPackagePick} (${l10n.createRoomPackageSoon})',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: isInteractive ? 0.88 : 0.68,
                          ),
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

class _ModeButton extends StatefulWidget {
  const _ModeButton({
    required this.selected,
    required this.enabled,
    required this.iconBuilder,
    required this.label,
    required this.onPressed,
  });

  final bool selected;
  final bool enabled;
  final Widget Function(Color color) iconBuilder;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_ModeButton> createState() => _ModeButtonState();
}

class _ModeButtonState extends State<_ModeButton> {
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
    final bool isLight = theme.brightness == Brightness.light;
    final bool isInteractive = widget.enabled;
    final double interaction =
        !isInteractive ? 0 : (_pressed ? 0.2 : (_hovered ? 0.12 : 0.06));
    final Color base = widget.selected && isInteractive
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: isLight ? 0.18 : 0.22),
            scheme.surfaceContainerHighest
                .withValues(alpha: isLight ? 0.86 : 0.54),
          )
        : scheme.surfaceContainerHighest
            .withValues(alpha: isLight ? 0.66 : 0.44);
    final Color accent =
        widget.selected && isInteractive ? scheme.secondary : scheme.primary;
    final Color topColor = Color.alphaBlend(
      Colors.white.withValues(
        alpha: isInteractive ? (isLight ? 0.16 : 0.08) : 0.04,
      ),
      base,
    );
    final Color bottomColor = Color.alphaBlend(
      accent.withValues(alpha: isInteractive ? interaction : 0.02),
      base,
    );
    final Color borderColor = !isInteractive
        ? scheme.outline.withValues(alpha: 0.28)
        : widget.selected
        ? scheme.primary.withValues(alpha: _hovered ? 0.78 : 0.62)
        : scheme.outline.withValues(alpha: _hovered ? 0.56 : 0.42);
    final Color iconColor = !isInteractive
        ? scheme.onSurfaceVariant.withValues(alpha: 0.72)
        : widget.selected
            ? scheme.primary
            : scheme.onSurfaceVariant.withValues(alpha: 0.92);

    return MouseRegion(
      cursor:
          isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        scale: !isInteractive ? 1 : (_pressed ? 0.99 : (_hovered ? 1.01 : 1)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: AppSpacing.tapTargetMin + 6,
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
              onTap: isInteractive ? widget.onPressed : null,
              onHover: isInteractive ? _setHovered : null,
              onHighlightChanged: isInteractive ? _setPressed : null,
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (!isInteractive) {
                  return Colors.transparent;
                }
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: <Widget>[
                    widget.iconBuilder(iconColor),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: (isInteractive
                                  ? scheme.onSurface
                                  : scheme.onSurfaceVariant)
                              .withValues(
                            alpha: !isInteractive
                                ? 0.7
                                : (widget.selected ? 1 : 0.92),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 18,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 170),
                        curve: Curves.easeOut,
                        opacity: widget.selected && isInteractive ? 1 : 0,
                        child: Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: scheme.primary.withValues(alpha: 0.92),
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

class _CreateButton extends StatelessWidget {
  const _CreateButton({
    required this.onPressed,
    required this.isLoading,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final bool enabled = onPressed != null;
    final Color iconColor = enabled
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.66);

    return SizedBox(
      height: AppSpacing.tapTargetMin + 4,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              )
            : const Icon(Icons.rocket_launch_rounded),
        label: Text(
          l10n.createRoomCreateCta,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
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
