import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:guesstogether/core/app_version.dart';
import 'package:guesstogether/core/l10n/l10n.dart';
import 'package:guesstogether/core/theme/app_colors.dart';
import 'package:guesstogether/core/theme/app_spacing.dart';
import 'package:guesstogether/features/lobby/presentation/create_room_screen.dart';
import 'package:guesstogether/features/lobby/presentation/join_room_screen.dart';
import 'package:guesstogether/features/profile/presentation/profile_screen.dart';
import 'package:guesstogether/features/settings/presentation/settings_screen.dart';
import 'package:guesstogether/widgets/app_panel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String routePath = '/home';
  static const String routeName = 'home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _BrandTitle(),
              const SizedBox(height: AppSpacing.lg),
              const _DecorativeLane(),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _ActionTile(
                                icon: Icons.add_circle_outline_rounded,
                                title: l10n.homeCreateRoom,
                                onTap: () =>
                                    context.push(CreateRoomScreen.routePath),
                                gradientColors: const <Color>[
                                  Color(0xFF2B67B9),
                                  Color(0xFF1C4D91),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _ActionTile(
                                icon: Icons.login_rounded,
                                title: l10n.homeJoinByPassword,
                                onTap: () =>
                                    context.push(JoinRoomScreen.routePath),
                                gradientColors: const <Color>[
                                  Color(0xFF0F8168),
                                  Color(0xFF0A5F4D),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _ActionTile(
                                icon: Icons.person_outline_rounded,
                                title: l10n.homeProfile,
                                onTap: () =>
                                    context.push(ProfileScreen.routePath),
                                gradientColors: const <Color>[
                                  Color(0xFF6F4AA6),
                                  Color(0xFF543684),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _ActionTile(
                                icon: Icons.settings_rounded,
                                title: l10n.homeSettings,
                                onTap: () =>
                                    context.push(SettingsScreen.routePath),
                                gradientColors: const <Color>[
                                  Color(0xFF8C4D1A),
                                  Color(0xFF6B350D),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const _VersionBadge(),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    return Align(
      alignment: Alignment.center,
      child: Text(
        'v${AppVersion.display}',
        style: theme.textTheme.labelLarge?.copyWith(
          color: isLight
              ? const Color(0xFF5F6F93)
              : Colors.white.withValues(alpha: 0.72),
          letterSpacing: 0.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme text = theme.textTheme;
    final l10n = context.l10n;
    final bool isLight = theme.brightness == Brightness.light;
    final String title = l10n.appTitle;
    final List<Color> titleGradient = isLight
        ? <Color>[
            const Color(0xFF2B4F86),
            const Color(0xFF3C76CB),
            const Color(0xFF2F8A79),
          ]
        : <Color>[
            Colors.white,
            AppColors.accentElectricBlue.withValues(alpha: 0.95),
            AppColors.accentMint.withValues(alpha: 0.92),
          ];

    return Align(
      alignment: Alignment.center,
      child: ShaderMask(
        shaderCallback: (Rect rect) {
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: titleGradient,
          ).createShader(rect);
        },
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: text.displayLarge?.copyWith(
            color: Colors.white,
            letterSpacing: -0.5,
            fontSize: (text.displayLarge?.fontSize ?? 34) + 2,
          ),
        ),
      ),
    );
  }
}

class _DecorativeLane extends StatelessWidget {
  const _DecorativeLane();

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final Color dotA = isLight
        ? const Color(0xFF2E6BC4)
        : AppColors.accentElectricBlue.withValues(alpha: 0.95);
    final Color dotB = isLight
        ? const Color(0xFF2F8E7D)
        : AppColors.accentMint.withValues(alpha: 0.9);
    final Color dotC = isLight
        ? const Color(0xFFBA7B1F)
        : AppColors.accentSun.withValues(alpha: 0.92);
    final Color lineStrong = dotA.withValues(alpha: isLight ? 0.78 : 0.7);
    final Color lineSoft = dotB.withValues(alpha: isLight ? 0.5 : 0.45);

    return SizedBox(
      height: 16,
      child: Row(
        children: <Widget>[
          Expanded(
            child: _LaneLine(
              reverse: true,
              strong: lineStrong,
              soft: lineSoft,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Row(
            children: <Widget>[
              _GlowDot(color: dotA),
              const SizedBox(width: AppSpacing.sm),
              _GlowDot(color: dotB),
              const SizedBox(width: AppSpacing.sm),
              _GlowDot(color: dotC),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _LaneLine(
              strong: lineStrong,
              soft: lineSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _LaneLine extends StatelessWidget {
  const _LaneLine({
    required this.strong,
    required this.soft,
    this.reverse = false,
  });

  final Color strong;
  final Color soft;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = reverse
        ? <Color>[Colors.transparent, soft, strong]
        : <Color>[strong, soft, Colors.transparent];
    return Container(
      height: 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(colors: colors),
      ),
    );
  }
}

class _GlowDot extends StatelessWidget {
  const _GlowDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.gradientColors,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final List<Color> gradientColors;

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
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
    final TextTheme text = theme.textTheme;
    final bool isLight = theme.brightness == Brightness.light;
    final double interaction = _pressed ? 0.14 : (_hovered ? 0.09 : 0.04);
    final List<Color> tileGradient = <Color>[
      Color.alphaBlend(
        Colors.white.withValues(alpha: isLight ? 0.08 : 0.05),
        widget.gradientColors[0],
      ),
      Color.alphaBlend(
        theme.colorScheme.secondary.withValues(alpha: interaction),
        widget.gradientColors[1],
      ),
    ];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.988 : (_hovered ? 1.008 : 1),
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          offset: _pressed
              ? const Offset(0, 0.004)
              : (_hovered ? const Offset(0, -0.004) : Offset.zero),
          child: AppPanel(
            padding: EdgeInsets.zero,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: tileGradient,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: widget.onTap,
                onHover: _setHovered,
                onHighlightChanged: _setPressed,
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return Colors.black
                        .withValues(alpha: isLight ? 0.08 : 0.16);
                  }
                  if (states.contains(WidgetState.hovered)) {
                    return Colors.white
                        .withValues(alpha: isLight ? 0.08 : 0.06);
                  }
                  return Colors.transparent;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color:
                          Colors.white.withValues(alpha: _hovered ? 0.4 : 0.24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Colors.white.withValues(
                          alpha: _hovered
                              ? (isLight ? 0.15 : 0.12)
                              : (isLight ? 0.08 : 0.06),
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 170),
                        curve: Curves.easeOutCubic,
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Colors.white
                                  .withValues(alpha: _hovered ? 0.32 : 0.24),
                              Colors.white
                                  .withValues(alpha: _hovered ? 0.2 : 0.14),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white
                                .withValues(alpha: _hovered ? 0.52 : 0.3),
                          ),
                        ),
                        child: Icon(widget.icon, color: Colors.white),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          widget.title,
                          style:
                              text.titleMedium?.copyWith(color: Colors.white),
                        ),
                      ),
                      AnimatedSlide(
                        duration: const Duration(milliseconds: 170),
                        curve: Curves.easeOutCubic,
                        offset: _hovered ? const Offset(0.08, 0) : Offset.zero,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
