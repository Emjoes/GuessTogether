import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
import 'package:guesstogether/core/theme/app_spacing.dart';
import 'package:guesstogether/core/theme/app_theme.dart';
import 'package:guesstogether/widgets/app_panel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String routePath = '/settings';
  static const String routeName = 'settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final StateController<ThemeMode> themeModeNotifier =
        ref.read(themeModeProvider.notifier);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
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

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
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
                      AppStrings.settingsTheme,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ThemeModeButton(
                      selected: themeMode == ThemeMode.system,
                      icon: Icons.phone_android_rounded,
                      label: AppStrings.settingsThemeSystem,
                      onPressed: () => themeModeNotifier.state = ThemeMode.system,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ThemeModeButton(
                      selected: themeMode == ThemeMode.light,
                      icon: Icons.wb_sunny_rounded,
                      label: AppStrings.settingsThemeLight,
                      onPressed: () => themeModeNotifier.state = ThemeMode.light,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ThemeModeButton(
                      selected: themeMode == ThemeMode.dark,
                      icon: Icons.nights_stay_rounded,
                      label: AppStrings.settingsThemeDark,
                      onPressed: () => themeModeNotifier.state = ThemeMode.dark,
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

class _ThemeModeButton extends StatefulWidget {
  const _ThemeModeButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_ThemeModeButton> createState() => _ThemeModeButtonState();
}

class _ThemeModeButtonState extends State<_ThemeModeButton> {
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
                    Icon(widget.icon, size: 20, color: iconColor),
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
