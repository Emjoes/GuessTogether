import 'package:flutter/material.dart';
import 'package:guesstogether/core/theme/app_spacing.dart';

/// Ensures 48x48 tap target for icon-only actions.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final String tooltipText = tooltip ?? semanticLabel;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: tooltipText,
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(
            width: AppSpacing.tapTargetMin,
            height: AppSpacing.tapTargetMin,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon),
          ),
        ),
      ),
    );
  }
}
