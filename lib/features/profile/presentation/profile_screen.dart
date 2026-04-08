import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:guesstogether/core/l10n/generated/app_localizations.dart';
import 'package:guesstogether/core/l10n/l10n.dart';
import 'package:guesstogether/core/theme/app_spacing.dart';
import 'package:guesstogether/data/api/game_api.dart';
import 'package:guesstogether/features/session/app_session_controller.dart';
import 'package:guesstogether/widgets/app_panel.dart';
import 'package:guesstogether/widgets/back_shortcut_scope.dart';

final profileProvider = FutureProvider.autoDispose<ProfileSummary>((ref) async {
  final GameApi api = ref.watch(gameApiProvider);
  return api.loadProfile();
});

final leaderboardScopeProvider = StateProvider<LeaderboardScope>(
  (ref) => LeaderboardScope.global,
);

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final GameApi api = ref.watch(gameApiProvider);
  final LeaderboardScope scope = ref.watch(leaderboardScopeProvider);
  return api.loadLeaderboard(scope);
});

enum ProfileTabSection { statistics, leaderboards, achievements }

final profileTabProvider = StateProvider<ProfileTabSection>(
  (ref) => ProfileTabSection.statistics,
);

final showCompletedAchievementsProvider = StateProvider<bool>(
  (ref) => true,
);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const String routePath = '/profile';
  static const String routeName = 'profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final AsyncValue<ProfileSummary> profileAsync = ref.watch(profileProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;
    final Color panelBase =
        scheme.surfaceContainerHighest.withValues(alpha: isLight ? 0.76 : 0.58);
    final Gradient panelGradient = LinearGradient(
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
        appBar: AppBar(title: Text(l10n.profileTitle)),
        body: SafeArea(
          child: profileAsync.when(
            data: (ProfileSummary profile) {
              final _ProfileMetrics metrics =
                  _ProfileMetrics.fromProfile(profile);
              final List<_RecentGame> recentGames = _buildRecentGames(
                context: context,
                l10n: l10n,
                recentGames: profile.recentGames,
              );
              final List<_AchievementItem> achievements = _buildAchievements(
                l10n: l10n,
                wins: metrics.wins,
                clutchCorrectAnswers: profile.clutchCorrectAnswers,
              );

              final AsyncValue<List<LeaderboardEntry>> leaderboardAsync =
                  ref.watch(leaderboardProvider);
              final LeaderboardScope selectedScope =
                  ref.watch(leaderboardScopeProvider);
              final StateController<LeaderboardScope> scopeController =
                  ref.read(leaderboardScopeProvider.notifier);
              final ProfileTabSection selectedTab =
                  ref.watch(profileTabProvider);
              final StateController<ProfileTabSection> tabController =
                  ref.read(profileTabProvider.notifier);
              final bool showCompletedAchievements =
                  ref.watch(showCompletedAchievementsProvider);
              final StateController<bool> showCompletedController =
                  ref.read(showCompletedAchievementsProvider.notifier);

              void handleTabChanged(ProfileTabSection tab) {
                if (tab == ProfileTabSection.leaderboards) {
                  ref.invalidate(leaderboardProvider);
                }
                tabController.state = tab;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _UserHeader(
                      profile: profile,
                      level: metrics.level,
                      progress: metrics.xpProgress,
                      xpInLevel: metrics.xpInLevel,
                      xpPerLevel: _ProfileMetrics.xpPerLevel,
                      gradient: panelGradient,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ProfileTabSelector(
                      selectedTab: selectedTab,
                      onChanged: handleTabChanged,
                      gradient: panelGradient,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (selectedTab == ProfileTabSection.statistics)
                      _StatisticsSection(
                        profile: profile,
                        metrics: metrics,
                        recentGames: recentGames,
                        gradient: panelGradient,
                      )
                    else if (selectedTab == ProfileTabSection.leaderboards)
                      _LeaderboardsSection(
                        leaderboardAsync: leaderboardAsync,
                        selectedScope: selectedScope,
                        onScopeChanged: (LeaderboardScope scope) {
                          scopeController.state = scope;
                        },
                        gradient: panelGradient,
                      )
                    else
                      _AchievementsSection(
                        achievements: achievements,
                        showCompleted: showCompletedAchievements,
                        onShowCompletedChanged: (bool value) =>
                            showCompletedController.state = value,
                        gradient: panelGradient,
                      ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object _, StackTrace __) =>
                Center(child: Text(l10n.profileLoadFailed)),
          ),
        ),
      ),
    );
  }
}

class _ProfileMetrics {
  const _ProfileMetrics({
    required this.wins,
    required this.losses,
    required this.totalXp,
    required this.level,
    required this.xpInLevel,
  });

  static const int xpPerLevel = 1200;

  factory _ProfileMetrics.fromProfile(ProfileSummary profile) {
    final int wins = math.max(0, profile.wins);
    final int losses = math.max(0, profile.losses);
    final int totalXp = profile.totalXp > 0
        ? profile.totalXp
        : (profile.gamesPlayed * 140) + (wins * 70) + (profile.bestScore ~/ 7);
    final int level =
        totalXp <= 0 ? 0 : (((totalXp - 1) ~/ xpPerLevel) + 1);
    final int xpInLevel = totalXp <= 0 ? 0 : (totalXp % xpPerLevel);

    return _ProfileMetrics(
      wins: wins,
      losses: losses,
      totalXp: totalXp,
      level: level,
      xpInLevel: xpInLevel,
    );
  }

  final int wins;
  final int losses;
  final int totalXp;
  final int level;
  final int xpInLevel;

  double get xpProgress => xpInLevel / xpPerLevel;
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({
    required this.profile,
    required this.level,
    required this.progress,
    required this.xpInLevel,
    required this.xpPerLevel,
    required this.gradient,
  });

  final ProfileSummary profile;
  final int level;
  final double progress;
  final int xpInLevel;
  final int xpPerLevel;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;
    final int xpToNextLevel = math.max(0, xpPerLevel - xpInLevel);

    return AppPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      radius: 20,
      gradient: gradient,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      scheme.primary.withValues(alpha: 0.96),
                      scheme.secondary.withValues(alpha: 0.88),
                    ],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.26),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    profile.displayName[0].toUpperCase(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  profile.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _LevelBadge(level: level),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              color: scheme.primary.withValues(alpha: 0.95),
              backgroundColor: Color.alphaBlend(
                scheme.surfaceContainerHighest
                    .withValues(alpha: isLight ? 0.5 : 0.36),
                scheme.primary.withValues(alpha: isLight ? 0.14 : 0.22),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              Text(
                l10n.profileXpProgress(xpInLevel, xpPerLevel),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                ),
              ),
              const Spacer(),
              Text(
                l10n.profileXpToNextLevel(xpToNextLevel),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(
              Colors.white.withValues(alpha: isLight ? 0.14 : 0.08),
              scheme.primary.withValues(alpha: 0.94),
            ),
            Color.alphaBlend(
              scheme.secondary.withValues(alpha: isLight ? 0.18 : 0.24),
              scheme.primary.withValues(alpha: 0.9),
            ),
          ],
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.62)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.primary.withValues(alpha: isLight ? 0.26 : 0.34),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _ProfileTabSelector extends StatelessWidget {
  const _ProfileTabSelector({
    required this.selectedTab,
    required this.onChanged,
    required this.gradient,
  });

  final ProfileTabSection selectedTab;
  final ValueChanged<ProfileTabSection> onChanged;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget buildButton({
      required bool selected,
      required IconData icon,
      required String label,
      required ProfileTabSection tab,
    }) {
      return _GradientToggleButton(
        selected: selected,
        icon: icon,
        label: label,
        iconOnly: true,
        onPressed: () => onChanged(tab),
      );
    }

    return AppPanel(
      padding: const EdgeInsets.all(6),
      gradient: gradient,
      radius: 18,
      child: Row(
        children: <Widget>[
          Expanded(
            child: buildButton(
              selected: selectedTab == ProfileTabSection.statistics,
              icon: Icons.bar_chart_rounded,
              label: l10n.profileTabStats,
              tab: ProfileTabSection.statistics,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: buildButton(
              selected: selectedTab == ProfileTabSection.leaderboards,
              icon: Icons.emoji_events_rounded,
              label: l10n.profileTabLeaderboards,
              tab: ProfileTabSection.leaderboards,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: buildButton(
              selected: selectedTab == ProfileTabSection.achievements,
              icon: Icons.workspace_premium_rounded,
              label: l10n.profileTabAchievements,
              tab: ProfileTabSection.achievements,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsSection extends StatelessWidget {
  const _StatisticsSection({
    required this.profile,
    required this.metrics,
    required this.recentGames,
    required this.gradient,
  });

  final ProfileSummary profile;
  final _ProfileMetrics metrics;
  final List<_RecentGame> recentGames;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final int played = profile.gamesPlayed;

    return AppPanel(
      gradient: gradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.profileStatsLabel,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          _WinLossOverview(
            played: played,
            wins: metrics.wins,
            losses: metrics.losses,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.profileRecentGames,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (recentGames.isEmpty)
            Text(
              l10n.profileNoRecentGames,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            )
          else
            Column(
              children: List<Widget>.generate(recentGames.length, (int index) {
                final _RecentGame game = recentGames[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == recentGames.length - 1 ? 0 : AppSpacing.sm,
                  ),
                  child: _RecentGameRow(game: game),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _WinLossOverview extends StatelessWidget {
  const _WinLossOverview({
    required this.played,
    required this.wins,
    required this.losses,
  });

  final int played;
  final int wins;
  final int losses;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: <Widget>[
        Expanded(
          child: _CounterCard(
            label: l10n.profileWins,
            value: '$wins',
            icon: Icons.check_circle_rounded,
            tone: _CounterCardTone.positive,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _CounterCard(
            label: l10n.profileLosses,
            value: '$losses',
            icon: Icons.cancel_rounded,
            tone: _CounterCardTone.negative,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _CounterCard(
            label: l10n.profileGamesPlayed,
            value: '$played',
            icon: Icons.sports_esports_rounded,
            tone: _CounterCardTone.neutral,
          ),
        ),
      ],
    );
  }
}

enum _CounterCardTone { neutral, positive, negative }

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final _CounterCardTone tone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;
    final Color accent = switch (tone) {
      _CounterCardTone.positive => const Color(0xFF21B25B),
      _CounterCardTone.negative => scheme.error,
      _CounterCardTone.neutral => scheme.primary,
    };
    final double accentAlpha = switch (tone) {
      _CounterCardTone.positive => isLight ? 0.18 : 0.28,
      _CounterCardTone.negative => isLight ? 0.16 : 0.24,
      _CounterCardTone.neutral => isLight ? 0.08 : 0.14,
    };
    final double surfaceAlpha = switch (tone) {
      _CounterCardTone.positive => isLight ? 0.78 : 0.62,
      _CounterCardTone.negative => isLight ? 0.78 : 0.62,
      _CounterCardTone.neutral => isLight ? 0.72 : 0.56,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: accent.withValues(alpha: isLight ? 0.45 : 0.6)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(
              Colors.white.withValues(alpha: isLight ? 0.16 : 0.08),
              scheme.surfaceContainerHighest.withValues(alpha: surfaceAlpha),
            ),
            Color.alphaBlend(
              accent.withValues(alpha: accentAlpha),
              scheme.surfaceContainerHighest
                  .withValues(alpha: isLight ? 0.68 : 0.52),
            ),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 20, color: accent.withValues(alpha: 0.96)),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.94),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardsSection extends StatelessWidget {
  const _LeaderboardsSection({
    required this.leaderboardAsync,
    required this.selectedScope,
    required this.onScopeChanged,
    required this.gradient,
  });

  final AsyncValue<List<LeaderboardEntry>> leaderboardAsync;
  final LeaderboardScope selectedScope;
  final ValueChanged<LeaderboardScope> onScopeChanged;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return AppPanel(
      gradient: gradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.profileLeaderboards,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          leaderboardAsync.when(
            data: (List<LeaderboardEntry> entries) {
              final List<_LeaderboardRowData> rows =
                  _buildLeaderboardRows(entries);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _GradientToggleButton(
                          selected: selectedScope == LeaderboardScope.global,
                          icon: Icons.public_rounded,
                          label: l10n.profileLeaderboardGlobal,
                          onPressed: () =>
                              onScopeChanged(LeaderboardScope.global),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _GradientToggleButton(
                          selected: selectedScope == LeaderboardScope.monthly,
                          icon: Icons.calendar_month_rounded,
                          label: l10n.profileLeaderboardMonth,
                          onPressed: () =>
                              onScopeChanged(LeaderboardScope.monthly),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _GradientToggleButton(
                          selected: selectedScope == LeaderboardScope.daily,
                          icon: Icons.today_rounded,
                          label: l10n.profileLeaderboardDay,
                          onPressed: () =>
                              onScopeChanged(LeaderboardScope.daily),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (rows.isEmpty)
                    Text(
                      l10n.profileNoLeaderboardData,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                      ),
                    )
                  else
                    Column(
                      children: List<Widget>.generate(
                        math.min(rows.length, 10),
                        (int index) {
                          final _LeaderboardRowData row = rows[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == math.min(rows.length, 10) - 1
                                  ? 0
                                  : AppSpacing.sm,
                            ),
                            child: _LeaderboardRow(
                              rank: index + 1,
                              row: row,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object _, StackTrace __) => Text(
              l10n.profileNoLeaderboardData,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection({
    required this.achievements,
    required this.showCompleted,
    required this.onShowCompletedChanged,
    required this.gradient,
  });

  final List<_AchievementItem> achievements;
  final bool showCompleted;
  final ValueChanged<bool> onShowCompletedChanged;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;
    final int unlockedCount =
        achievements.where((_AchievementItem item) => item.unlocked).length;
    final List<_AchievementItem> visibleAchievements = showCompleted
        ? achievements
        : achievements
            .where((_AchievementItem item) => !item.unlocked)
            .toList(growable: false);

    return AppPanel(
      gradient: gradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                l10n.profileAchievements,
                style: theme.textTheme.titleSmall,
              ),
              const Spacer(),
              Text(
                l10n.profileUnlockedCount(unlockedCount, achievements.length),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.38)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color.alphaBlend(
                    Colors.white.withValues(alpha: isLight ? 0.14 : 0.06),
                    scheme.surfaceContainerHighest
                        .withValues(alpha: isLight ? 0.68 : 0.5),
                  ),
                  Color.alphaBlend(
                    scheme.primary.withValues(alpha: isLight ? 0.08 : 0.12),
                    scheme.surfaceContainerHighest
                        .withValues(alpha: isLight ? 0.64 : 0.46),
                  ),
                ],
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.profileShowCompleted,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                Switch(
                  value: showCompleted,
                  onChanged: onShowCompletedChanged,
                  activeThumbColor: scheme.primary,
                  activeTrackColor: scheme.primary.withValues(alpha: 0.36),
                  inactiveThumbColor:
                      scheme.onSurfaceVariant.withValues(alpha: 0.95),
                  inactiveTrackColor: scheme.outline.withValues(alpha: 0.38),
                  trackOutlineColor:
                      const WidgetStatePropertyAll<Color>(Colors.transparent),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children:
                List<Widget>.generate(visibleAchievements.length, (int index) {
              final _AchievementItem item = visibleAchievements[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == visibleAchievements.length - 1
                      ? 0
                      : AppSpacing.sm,
                ),
                child: _AchievementCard(item: item),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _GradientToggleButton extends StatefulWidget {
  const _GradientToggleButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconOnly = false,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool iconOnly;

  @override
  State<_GradientToggleButton> createState() => _GradientToggleButtonState();
}

class _GradientToggleButtonState extends State<_GradientToggleButton> {
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
        : scheme.surfaceContainerHighest
            .withValues(alpha: isLight ? 0.66 : 0.44);
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

    final Widget buttonContent = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.iconOnly ? 0 : AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(widget.icon, size: widget.iconOnly ? 20 : 18, color: iconColor),
          if (!widget.iconOnly) ...<Widget>[
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface.withValues(
                    alpha: widget.selected ? 1 : 0.92,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

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
          height: AppSpacing.tapTargetMin + 2,
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
                  return scheme.primary
                      .withValues(alpha: isLight ? 0.06 : 0.12);
                }
                return Colors.transparent;
              }),
              child: Semantics(
                button: true,
                selected: widget.selected,
                label: widget.label,
                child: widget.iconOnly
                    ? Tooltip(
                        message: widget.label,
                        child: buttonContent,
                      )
                    : buttonContent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentGameRow extends StatelessWidget {
  const _RecentGameRow({required this.game});

  final _RecentGame game;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;
    final Color resultColor = game.wasHost
        ? scheme.onSurfaceVariant.withValues(alpha: 0.82)
        : game.won
            ? scheme.secondary.withValues(alpha: 0.95)
            : scheme.error.withValues(alpha: 0.9);
    final Widget modeIcon = game.mode == _RecentGameMode.duel
        ? _CrossedSwordsIcon(
            size: 17,
            color: scheme.primary.withValues(alpha: 0.95),
          )
        : Icon(
            Icons.diversity_3_rounded,
            size: 18,
            color: scheme.primary.withValues(alpha: 0.95),
          );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.36)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(
              Colors.white.withValues(alpha: isLight ? 0.14 : 0.06),
              scheme.surfaceContainerHighest
                  .withValues(alpha: isLight ? 0.65 : 0.5),
            ),
            Color.alphaBlend(
              scheme.primary.withValues(alpha: isLight ? 0.06 : 0.1),
              scheme.surfaceContainerHighest
                  .withValues(alpha: isLight ? 0.6 : 0.46),
            ),
          ],
        ),
      ),
      child: Row(
        children: <Widget>[
          modeIcon,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(game.title, style: theme.textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(
                  '${game.modeLabel} - ${game.whenLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (game.score != null) ...<Widget>[
            Text(
              '${game.score}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary.withValues(alpha: 0.96),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: resultColor.withValues(alpha: 0.16),
              border: Border.all(color: resultColor.withValues(alpha: 0.5)),
            ),
            child: Icon(
              game.wasHost
                  ? Icons.person_rounded
                  : game.won
                      ? Icons.check_rounded
                      : Icons.close_rounded,
              size: 14,
              color: resultColor,
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
        center: Offset(0, gripLength * 0.52),
        width: gripWidth,
        height: gripLength,
      ),
      Radius.circular(gripWidth / 2),
    );
    canvas.drawRRect(grip, handlePaint);

    canvas.drawCircle(
      Offset(0, gripLength + pommelRadius * 0.6),
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

enum _AchievementTier { common, rare, epic }

class _AchievementItem {
  const _AchievementItem({
    required this.title,
    required this.requirement,
    required this.icon,
    required this.tier,
    required this.progress,
    required this.target,
    required this.rewardXp,
  });

  final String title;
  final String requirement;
  final IconData icon;
  final _AchievementTier tier;
  final int progress;
  final int target;
  final int rewardXp;

  bool get unlocked => progress >= target;

  int get displayProgress => math.min(progress, target);
}

extension on _AchievementTier {
  Color startColor(ColorScheme scheme) {
    switch (this) {
      case _AchievementTier.common:
        return scheme.secondary.withValues(alpha: 0.9);
      case _AchievementTier.rare:
        return scheme.primary.withValues(alpha: 0.95);
      case _AchievementTier.epic:
        return scheme.tertiary.withValues(alpha: 0.96);
    }
  }

  Color endColor(ColorScheme scheme) {
    switch (this) {
      case _AchievementTier.common:
        return scheme.primary.withValues(alpha: 0.82);
      case _AchievementTier.rare:
        return scheme.secondary.withValues(alpha: 0.84);
      case _AchievementTier.epic:
        return scheme.primary.withValues(alpha: 0.88);
    }
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.item});

  final _AchievementItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;
    final Color tierStart = item.tier.startColor(scheme);
    final Color tierEnd = item.tier.endColor(scheme);
    final double contentOpacity = item.unlocked ? 1 : 0.6;
    final TextStyle? bottomValueStyle = theme.textTheme.labelSmall?.copyWith(
      color: tierStart.withValues(alpha: 0.95),
      fontWeight: FontWeight.w700,
    );

    return Opacity(
      opacity: contentOpacity,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.unlocked
                ? tierStart.withValues(alpha: 0.6)
                : scheme.outline.withValues(alpha: 0.34),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color.alphaBlend(
                Colors.white.withValues(alpha: isLight ? 0.2 : 0.08),
                tierStart.withValues(alpha: item.unlocked ? 0.24 : 0.08),
              ),
              Color.alphaBlend(
                scheme.surfaceContainerHighest
                    .withValues(alpha: isLight ? 0.72 : 0.5),
                tierEnd.withValues(alpha: item.unlocked ? 0.26 : 0.08),
              ),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[tierStart, tierEnd],
                    ),
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.title,
                    style: theme.textTheme.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.requirement,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (item.displayProgress / item.target).clamp(0, 1),
                minHeight: 6,
                color: tierStart.withValues(alpha: 0.9),
                backgroundColor: tierStart.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                Text(
                  l10n.profileProgressValue(item.displayProgress, item.target),
                  style: bottomValueStyle,
                ),
                const Spacer(),
                Text(
                  l10n.profileRewardXp(item.rewardXp),
                  style: bottomValueStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRowData {
  const _LeaderboardRowData({
    required this.playerName,
    required this.wins,
  });

  final String playerName;
  final int wins;
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.row,
  });

  final int rank;
  final _LeaderboardRowData row;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;
    final bool top3 = rank <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: top3
              ? scheme.tertiary.withValues(alpha: 0.42)
              : scheme.outline.withValues(alpha: 0.36),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(
              Colors.white.withValues(alpha: isLight ? 0.14 : 0.06),
              scheme.surfaceContainerHighest
                  .withValues(alpha: isLight ? 0.65 : 0.5),
            ),
            Color.alphaBlend(
              (top3 ? scheme.tertiary : scheme.primary)
                  .withValues(alpha: isLight ? 0.09 : 0.12),
              scheme.surfaceContainerHighest
                  .withValues(alpha: isLight ? 0.6 : 0.46),
            ),
          ],
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: (top3 ? scheme.tertiary : scheme.primary)
                  .withValues(alpha: isLight ? 0.16 : 0.22),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: top3 ? scheme.tertiary : scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              row.playerName,
              style: theme.textTheme.labelLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${row.wins}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.primary.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentGame {
  const _RecentGame({
    required this.title,
    required this.won,
    required this.whenLabel,
    required this.modeLabel,
    required this.mode,
    this.score,
    this.wasHost = false,
  });

  final String title;
  final int? score;
  final bool won;
  final String whenLabel;
  final String modeLabel;
  final _RecentGameMode mode;
  final bool wasHost;
}

enum _RecentGameMode { multiplayer, duel }

List<_RecentGame> _buildRecentGames({
  required BuildContext context,
  required AppLocalizations l10n,
  required List<ProfileRecentGame> recentGames,
}) {
  return recentGames.map((ProfileRecentGame game) {
    final _RecentGameMode mode = game.mode == 'duel'
        ? _RecentGameMode.duel
        : _RecentGameMode.multiplayer;
    return _RecentGame(
      title: game.roomName,
      score: game.score,
      won: game.won,
      whenLabel: _recentGameWhenLabel(
        context: context,
        playedAtEpochMs: game.playedAtEpochMs,
      ),
      modeLabel: mode == _RecentGameMode.duel
          ? l10n.createRoomModeDuel
          : l10n.createRoomModeMultiplayer,
      mode: mode,
      wasHost: game.wasHost,
    );
  }).toList(growable: false);
}

List<_AchievementItem> _buildAchievements({
  required AppLocalizations l10n,
  required int wins,
  required int clutchCorrectAnswers,
}) {
  return <_AchievementItem>[
    _AchievementItem(
      title: l10n.achievementFirstWinTitle,
      requirement: l10n.achievementFirstWinRequirement,
      icon: Icons.emoji_events_rounded,
      tier: _AchievementTier.epic,
      progress: wins,
      target: 1,
      rewardXp: 500,
    ),
    _AchievementItem(
      title: l10n.achievementClutchAnswerTitle,
      requirement: l10n.achievementClutchAnswerRequirement,
      icon: Icons.psychology_alt_rounded,
      tier: _AchievementTier.epic,
      progress: clutchCorrectAnswers,
      target: 1,
      rewardXp: 750,
    ),
  ];
}

List<_LeaderboardRowData> _buildLeaderboardRows(
    List<LeaderboardEntry> entries) {
  final List<_LeaderboardRowData> rows = entries
      .map(
        (LeaderboardEntry entry) => _LeaderboardRowData(
          playerName: entry.playerName,
          wins: entry.score,
        ),
      )
      .toList();

  rows.sort((_LeaderboardRowData a, _LeaderboardRowData b) {
    final int byWins = b.wins.compareTo(a.wins);
    if (byWins != 0) {
      return byWins;
    }
    return a.playerName.compareTo(b.playerName);
  });

  return rows;
}

String _recentGameWhenLabel({
  required BuildContext context,
  required int playedAtEpochMs,
}) {
  if (playedAtEpochMs <= 0) {
    return '--.--.--';
  }

  final DateTime playedAt =
      DateTime.fromMillisecondsSinceEpoch(playedAtEpochMs);
  final String localeName = Localizations.localeOf(context).toLanguageTag();
  return DateFormat('dd.MM.yy', localeName).format(playedAt);
}
