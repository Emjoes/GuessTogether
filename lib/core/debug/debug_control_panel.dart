import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guesstogether/core/debug/loading_debug_gate.dart';
import 'package:guesstogether/features/game/providers/game_providers.dart';

class DebugControlPanel extends ConsumerWidget {
  const DebugControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final GameViewRole role = ref.watch(gameViewRoleProvider);
    final String localPlayerId = ref.watch(localPlayerIdProvider);
    const List<String> selectablePlayerIds = <String>['p1', 'p2', 'p3', 'p4'];
    final String effectiveLocalPlayerId = selectablePlayerIds.contains(
      localPlayerId,
    )
        ? localPlayerId
        : selectablePlayerIds.first;

    return Positioned(
      top: 10,
      right: 10,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: LoadingDebugGate.instance,
          builder: (BuildContext context, _) {
            final ThemeData appTheme = Theme.of(context);
            final bool isLight = appTheme.brightness == Brightness.light;
            final Color panelSurface =
                isLight ? const Color(0xFFF5F9FF) : const Color(0xFF111826);
            final Color panelOnSurface =
                isLight ? const Color(0xFF1D2B44) : Colors.white;
            final Color panelBorder = isLight
                ? const Color(0xFF6E82A9).withValues(alpha: 0.34)
                : Colors.white.withValues(alpha: 0.22);
            final Color panelShadow = isLight
                ? const Color(0xFF51698F).withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.34);
            final bool loadHoldSupported = isLoadingDebugGateSupported;
            final bool loadHoldEnabled = LoadingDebugGate.instance.enabled;
            final ThemeData panelTheme = ThemeData(
              useMaterial3: true,
              brightness: isLight ? Brightness.light : Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor:
                    isLight ? const Color(0xFF3D79D4) : const Color(0xFF79B8FF),
                brightness: isLight ? Brightness.light : Brightness.dark,
              ),
              inputDecorationTheme: InputDecorationTheme(
                isDense: true,
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight
                        ? const Color(0xFF9FB2D8)
                        : const Color(0x4DFFFFFF),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isLight
                        ? const Color(0xFF3D79D4)
                        : const Color(0xFF79B8FF),
                    width: 1.2,
                  ),
                ),
                labelStyle: TextStyle(
                  color: isLight
                      ? const Color(0xFF3D4F71)
                      : const Color(0xCCFFFFFF),
                ),
              ),
            );

            return Material(
              color: Colors.transparent,
              child: Theme(
                data: panelTheme,
                child: Container(
                  width: 278,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        panelSurface.withValues(alpha: isLight ? 0.96 : 0.92),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: panelBorder),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: panelShadow,
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'DEBUG PANEL',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: panelOnSurface,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                      ),
                      const SizedBox(height: 10),
                      _SectionTitle(
                        title: 'Loading Hold',
                        status: loadHoldSupported
                            ? (loadHoldEnabled ? 'ON' : 'OFF')
                            : 'UNSUPPORTED',
                        isLight: isLight,
                        statusColor: !loadHoldSupported
                            ? Colors.grey
                            : (loadHoldEnabled
                                ? const Color(0xFFFF7F5C)
                                : const Color(0xFF7FD6A0)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: loadHoldSupported
                                  ? LoadingDebugGate.instance.toggle
                                  : null,
                              child:
                                  Text(loadHoldEnabled ? 'Disable' : 'Enable'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: loadHoldSupported && loadHoldEnabled
                                  ? LoadingDebugGate.instance.releaseOnce
                                  : null,
                              child: const Text('Step'),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1),
                      ),
                      _SectionTitle(
                        title: 'Match Role',
                        status: role == GameViewRole.host ? 'HOST' : 'PLAYER',
                        isLight: isLight,
                        statusColor: role == GameViewRole.host
                            ? const Color(0xFF79B8FF)
                            : const Color(0xFF8CE3AE),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _RoleButton(
                              label: 'Host',
                              selected: role == GameViewRole.host,
                              isLight: isLight,
                              accent: const Color(0xFF79B8FF),
                              onTap: () {
                                ref.read(gameViewRoleProvider.notifier).state =
                                    GameViewRole.host;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RoleButton(
                              label: 'Player',
                              selected: role == GameViewRole.player,
                              isLight: isLight,
                              accent: const Color(0xFF8CE3AE),
                              onTap: () {
                                ref.read(gameViewRoleProvider.notifier).state =
                                    GameViewRole.player;
                              },
                            ),
                          ),
                        ],
                      ),
                      if (role == GameViewRole.player) ...<Widget>[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: isLight
                                ? const Color(0xFFEAF1FF)
                                : const Color(0xFF1A273A),
                            border: Border.all(
                              color: isLight
                                  ? const Color(0xFF9FB2D8)
                                  : Colors.white.withValues(alpha: 0.26),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                'Local player',
                                style: TextStyle(
                                  color: panelOnSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SegmentedButton<String>(
                                showSelectedIcon: false,
                                segments: selectablePlayerIds
                                    .map(
                                      (String id) => ButtonSegment<String>(
                                        value: id,
                                        label: Text(id.toUpperCase()),
                                      ),
                                    )
                                    .toList(),
                                selected: <String>{effectiveLocalPlayerId},
                                onSelectionChanged: (Set<String> selectedIds) {
                                  if (selectedIds.isEmpty) {
                                    return;
                                  }
                                  ref
                                      .read(localPlayerIdProvider.notifier)
                                      .state = selectedIds.first;
                                },
                                style: ButtonStyle(
                                  foregroundColor:
                                      WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                                      if (states
                                          .contains(WidgetState.selected)) {
                                        return isLight
                                            ? Colors.white
                                            : const Color(0xFF0E1A2A);
                                      }
                                      return isLight
                                          ? const Color(0xFF2A3C5A)
                                          : Colors.white;
                                    },
                                  ),
                                  backgroundColor:
                                      WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                                      if (states
                                          .contains(WidgetState.selected)) {
                                        return isLight
                                            ? const Color(0xFF3D79D4)
                                            : const Color(0xFF79B8FF);
                                      }
                                      return isLight
                                          ? const Color(0xFFDCE8FF)
                                          : Colors.white
                                              .withValues(alpha: 0.08);
                                    },
                                  ),
                                  side: WidgetStateProperty.resolveWith<
                                      BorderSide>(
                                    (Set<WidgetState> states) {
                                      if (states
                                          .contains(WidgetState.selected)) {
                                        return BorderSide(
                                          color: isLight
                                              ? const Color(0xFF3D79D4)
                                              : const Color(0xFF79B8FF),
                                        );
                                      }
                                      return BorderSide(
                                        color: isLight
                                            ? const Color(0xFFB5C6E8)
                                            : Colors.white
                                                .withValues(alpha: 0.28),
                                      );
                                    },
                                  ),
                                  textStyle: WidgetStateProperty.all(
                                    const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.only(top: 10, bottom: 10),
                        child: Divider(height: 1),
                      ),
                      SizedBox(
                        height: 40,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFA93E3E),
                            foregroundColor: const Color(0xFFFFEBEB),
                            disabledBackgroundColor: const Color(0xFFA93E3E)
                                .withValues(alpha: isLight ? 0.3 : 0.34),
                            disabledForegroundColor:
                                const Color(0xFFFFEBEB).withValues(alpha: 0.62),
                          ),
                          onPressed: () {
                            final game = ref.read(gameControllerProvider);
                            if (game.isMatchEnded) {
                              return;
                            }
                            ref
                                .read(gameControllerProvider.notifier)
                                .finishMatchNow();
                          },
                          child: const Text('Finish Match'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.label,
    required this.selected,
    required this.isLight,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isLight;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        foregroundColor: selected
            ? (isLight ? Colors.white : const Color(0xFF0E1A2A))
            : (isLight ? const Color(0xFF253754) : Colors.white),
        backgroundColor: selected
            ? accent.withValues(alpha: 0.95)
            : (isLight
                ? const Color(0xFFE6EEFF)
                : Colors.white.withValues(alpha: 0.08)),
        side: BorderSide(
          color: selected
              ? accent
              : (isLight
                  ? const Color(0xFF9DB0D8)
                  : Colors.white.withValues(alpha: 0.3)),
        ),
      ),
      child: Text(label),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.status,
    required this.isLight,
    required this.statusColor,
  });

  final String title;
  final String status;
  final bool isLight;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isLight
                      ? const Color(0xFF2B3B58)
                      : Colors.white.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: statusColor.withValues(alpha: 0.2),
            border: Border.all(color: statusColor.withValues(alpha: 0.7)),
          ),
          child: Text(
            status,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}
