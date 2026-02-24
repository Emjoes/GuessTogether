import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:guesstogether/core/l10n/app_strings.dart';
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
              const SizedBox(height: AppSpacing.lg),
              _ActionTile(
                icon: Icons.add_circle_outline_rounded,
                title: AppStrings.homeCreateRoom,
                onTap: () => context.push(CreateRoomScreen.routePath),
                gradientColors: const <Color>[
                  Color(0xFF2B67B9),
                  Color(0xFF1C4D91),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _ActionTile(
                icon: Icons.password_rounded,
                title: AppStrings.homeJoinByPassword,
                onTap: () => context.push(JoinRoomScreen.routePath),
                gradientColors: const <Color>[
                  Color(0xFF0F8168),
                  Color(0xFF0A5F4D),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _ActionTile(
                icon: Icons.person_outline_rounded,
                title: AppStrings.homeProfile,
                onTap: () => context.push(ProfileScreen.routePath),
                gradientColors: const <Color>[
                  Color(0xFF6F4AA6),
                  Color(0xFF543684),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _ActionTile(
                icon: Icons.settings_rounded,
                title: AppStrings.homeSettings,
                onTap: () => context.push(SettingsScreen.routePath),
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
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme text = theme.textTheme;
    final bool isLight = theme.brightness == Brightness.light;
    const String title = AppStrings.appTitle;
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

class _ActionTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return AppPanel(
      padding: EdgeInsets.zero,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: text.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
