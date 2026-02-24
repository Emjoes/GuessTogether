import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
import 'package:guesstogether/core/theme/app_spacing.dart';
import 'package:guesstogether/features/game/presentation/game_screen.dart';
import 'package:guesstogether/features/lobby/providers/create_room_provider.dart';
import 'package:guesstogether/widgets/app_panel.dart';

class CreateRoomScreen extends ConsumerWidget {
  const CreateRoomScreen({super.key});

  static const String routePath = '/create-room';
  static const String routeName = 'createRoom';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CreateRoomState state = ref.watch(createRoomControllerProvider);
    final CreateRoomController controller =
        ref.read(createRoomControllerProvider.notifier);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;
    final bool isLight = theme.brightness == Brightness.light;
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
    Future<void> pickPackageFile() async {
      try {
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: <String>[
            'json',
            'csv',
            'txt',
            'zip',
            'xlsx',
          ],
        );
        if (result == null || result.files.isEmpty) {
          return;
        }
        final PlatformFile file = result.files.first;
        controller.setPackageFileName(file.name);
      } on Exception {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open file picker')),
          );
        }
      }
    }

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
                gradient: setupGradient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      AppStrings.createRoomDetailsLabel,
                      style: text.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: AppStrings.createRoomNameLabel,
                        hintText: 'Cool Quiz',
                      ),
                      onChanged: controller.setName,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: AppStrings.createRoomPasswordLabel,
                        hintText: '1234',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: controller.setPassword,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      AppStrings.createRoomModeLabel,
                      style: text.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Column(
                      children: <Widget>[
                        _ModeButton(
                          selected: state.mode == RoomMode.multiplayer,
                          iconBuilder: (Color color) => Icon(
                            Icons.diversity_3_rounded,
                            size: 20,
                            color: color,
                          ),
                          label: AppStrings.createRoomModeMultiplayer,
                          onPressed: () =>
                              controller.setMode(RoomMode.multiplayer),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _ModeButton(
                          selected: state.mode == RoomMode.duel,
                          iconBuilder: (Color color) =>
                              _CrossedSwordsIcon(size: 20, color: color),
                          label: AppStrings.createRoomModeDuel,
                          onPressed: () => controller.setMode(RoomMode.duel),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      AppStrings.createRoomPackageLabel,
                      style: text.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PackagePickerField(
                      fileName: state.packageFileName,
                      onPick: pickPackageFile,
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
                        await controller.createRoom();
                        if (context.mounted) {
                          context.push(GameScreen.routePath);
                        }
                      },
              ),
            ],
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
  });

  final String fileName;
  final VoidCallback onPick;

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
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;
    final bool hasFile = widget.fileName.isNotEmpty;
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
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.99 : (_hovered ? 1.01 : 1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: AppSpacing.tapTargetMin + 6),
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
              onTap: widget.onPick,
              onHover: _setHovered,
              onHighlightChanged: _setPressed,
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return scheme.primary.withValues(alpha: isLight ? 0.14 : 0.2);
                }
                if (states.contains(WidgetState.hovered)) {
                  return scheme.primary.withValues(alpha: isLight ? 0.06 : 0.12);
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
                      color: scheme.primary.withValues(alpha: 0.92),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        hasFile
                            ? widget.fileName
                            : AppStrings.createRoomPackagePick,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: hasFile
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant.withValues(alpha: 0.88),
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
    required this.iconBuilder,
    required this.label,
    required this.onPressed,
  });

  final bool selected;
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
    final double interaction = _pressed ? 0.2 : (_hovered ? 0.12 : 0.06);
    final Color base = widget.selected
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: isLight ? 0.18 : 0.22),
            scheme.surfaceContainerHighest
                .withValues(alpha: isLight ? 0.86 : 0.54),
          )
        : scheme.surfaceContainerHighest.withValues(alpha: isLight ? 0.66 : 0.44);
    final Color accent = widget.selected ? scheme.secondary : scheme.primary;
    final Color topColor = Color.alphaBlend(
      Colors.white.withValues(alpha: isLight ? 0.16 : 0.08),
      base,
    );
    final Color bottomColor = Color.alphaBlend(
      accent.withValues(alpha: interaction),
      base,
    );
    final Color borderColor = widget.selected
        ? scheme.primary.withValues(alpha: _hovered ? 0.78 : 0.62)
        : scheme.outline.withValues(alpha: _hovered ? 0.56 : 0.42);
    final Color iconColor = widget.selected
        ? scheme.primary
        : scheme.onSurfaceVariant.withValues(alpha: 0.92);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.99 : (_hovered ? 1.01 : 1),
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
              onTap: widget.onPressed,
              onHover: _setHovered,
              onHighlightChanged: _setPressed,
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return scheme.primary.withValues(alpha: isLight ? 0.14 : 0.2);
                }
                if (states.contains(WidgetState.hovered)) {
                  return scheme.primary.withValues(alpha: isLight ? 0.06 : 0.12);
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
                          color: scheme.onSurface.withValues(
                            alpha: widget.selected ? 1 : 0.92,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 18,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 170),
                        curve: Curves.easeOut,
                        opacity: widget.selected ? 1 : 0,
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

class _CreateButton extends StatefulWidget {
  const _CreateButton({
    required this.onPressed,
    required this.isLoading,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<_CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<_CreateButton> {
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
    final bool enabled = widget.onPressed != null;
    final double interaction = enabled ? (_pressed ? 0.16 : (_hovered ? 0.1 : 0.04)) : 0;
    final Color startBase = enabled
        ? scheme.primary
        : scheme.surfaceContainerHighest.withValues(alpha: isLight ? 0.5 : 0.38);
    final Color endBase = enabled
        ? Color.alphaBlend(
            scheme.secondary.withValues(alpha: isLight ? 0.22 : 0.16),
            scheme.primary.withValues(alpha: isLight ? 0.95 : 0.9),
          )
        : scheme.surfaceContainerHighest.withValues(alpha: isLight ? 0.42 : 0.32);
    final Color topColor = Color.alphaBlend(
      Colors.white.withValues(alpha: isLight ? 0.14 : 0.07),
      startBase,
    );
    final Color bottomColor = Color.alphaBlend(
      scheme.tertiary.withValues(alpha: interaction),
      endBase,
    );
    final Color borderColor = enabled
        ? scheme.primary.withValues(alpha: _hovered ? 0.82 : 0.66)
        : scheme.outline.withValues(alpha: 0.26);
    final Color contentColor = enabled
        ? scheme.onPrimary
        : scheme.onSurfaceVariant.withValues(alpha: 0.58);

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        scale: enabled ? (_pressed ? 0.988 : (_hovered ? 1.006 : 1)) : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          height: AppSpacing.tapTargetMin + 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[topColor, bottomColor],
            ),
            boxShadow: enabled
                ? <BoxShadow>[
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: isLight ? 0.24 : 0.3),
                      blurRadius: _hovered ? 22 : 14,
                      offset: Offset(0, _hovered ? 11 : 8),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              onHover: enabled ? _setHovered : null,
              onHighlightChanged: enabled ? _setPressed : null,
              borderRadius: BorderRadius.circular(16),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return Colors.black.withValues(alpha: isLight ? 0.12 : 0.2);
                }
                if (states.contains(WidgetState.hovered)) {
                  return Colors.white.withValues(alpha: isLight ? 0.08 : 0.06);
                }
                return Colors.transparent;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (widget.isLoading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(contentColor),
                        ),
                      )
                    else
                      Icon(Icons.rocket_launch_rounded, color: contentColor),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      AppStrings.createRoomCreateCta,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: contentColor,
                        fontWeight: FontWeight.w700,
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
