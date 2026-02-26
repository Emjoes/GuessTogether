import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:guesstogether/core/l10n/l10n.dart';
import 'package:guesstogether/core/theme/app_colors.dart';

class CircleTimer extends StatefulWidget {
  const CircleTimer({super.key, required this.remaining, required this.total});

  final int remaining;
  final int total;

  @override
  State<CircleTimer> createState() => _CircleTimerState();
}

class _CircleTimerState extends State<CircleTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void didUpdateWidget(covariant CircleTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  void _syncPulse() {
    final bool urgent = widget.remaining <= 5 && widget.remaining > 0;
    if (urgent) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
      }
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = widget.total == 0
        ? 0
        : (widget.remaining.clamp(0, widget.total) / widget.total);
    final bool urgent = widget.remaining <= 5 && widget.remaining > 0;

    return Semantics(
      label: context.l10n.timerSemanticsRemaining(widget.remaining),
      child: SizedBox(
        width: 64,
        height: 64,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final double pulseScale =
                urgent ? (1 + (_pulseController.value * 0.08)) : 1;
            return Transform.scale(
              scale: urgent ? pulseScale : 1,
              child: child,
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1, end: progress),
                duration: const Duration(milliseconds: 500),
                builder: (BuildContext context, double value, Widget? child) {
                  return RepaintBoundary(
                    child: CustomPaint(
                      painter: _TimerPainter(
                        fraction: value,
                        urgent: urgent,
                      ),
                    ),
                  );
                },
              ),
              Text(
                widget.remaining.toString(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  _TimerPainter({required this.fraction, required this.urgent});

  final double fraction;
  final bool urgent;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.width / 2;

    final Paint bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = AppColors.timerBase.withValues(alpha: 0.4);
    final Paint fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = urgent ? AppColors.timerUrgent : AppColors.accentElectricBlue;

    canvas.drawCircle(center, radius, bg);

    final double sweep = 2 * math.pi * fraction;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerPainter oldDelegate) {
    return oldDelegate.fraction != fraction || oldDelegate.urgent != urgent;
  }
}
