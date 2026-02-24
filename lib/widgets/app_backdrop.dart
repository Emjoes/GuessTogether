import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double height = constraints.maxHeight;
        return IgnorePointer(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isLight
                          ? const <Color>[
                              Color(0xFFFDFFFF),
                              Color(0xFFF7FBFF),
                            ]
                          : <Color>[
                              scheme.surface.withValues(alpha: 0.96),
                              scheme.surface.withValues(alpha: 0.99),
                            ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.64, -0.92),
                      radius: 1.8,
                      colors: <Color>[
                        scheme.primary.withValues(alpha: isLight ? 0.1 : 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -130,
                left: -100,
                child: _BlurHighlight(
                  width: 360,
                  height: 260,
                  angle: -0.34,
                  blurSigma: 32,
                  colorA:
                      scheme.primary.withValues(alpha: isLight ? 0.15 : 0.16),
                  colorB:
                      scheme.secondary.withValues(alpha: isLight ? 0.07 : 0.06),
                ),
              ),
              Positioned(
                top: 220,
                right: -140,
                child: _BlurHighlight(
                  width: 340,
                  height: 220,
                  angle: 0.42,
                  blurSigma: 34,
                  colorA:
                      scheme.secondary.withValues(alpha: isLight ? 0.14 : 0.14),
                  colorB:
                      scheme.primary.withValues(alpha: isLight ? 0.07 : 0.05),
                ),
              ),
              Positioned(
                bottom: -160,
                left: -20,
                child: _BlurHighlight(
                  width: 390,
                  height: 300,
                  angle: 0.18,
                  blurSigma: 36,
                  colorA:
                      scheme.tertiary.withValues(alpha: isLight ? 0.12 : 0.13),
                  colorB:
                      scheme.primary.withValues(alpha: isLight ? 0.05 : 0.04),
                ),
              ),
              Positioned(
                top: height * 0.08,
                left: -120,
                child: _BlurHighlight(
                  width: 300,
                  height: 180,
                  angle: 0.08,
                  blurSigma: 30,
                  colorA: scheme.primary.withValues(alpha: isLight ? 0.1 : 0.1),
                  colorB:
                      scheme.tertiary.withValues(alpha: isLight ? 0.05 : 0.04),
                ),
              ),
              Positioned(
                top: 96,
                right: 38,
                child: _SoftGlowOrb(
                  size: 130,
                  blurSigma: 26,
                  color: Colors.white.withValues(alpha: isLight ? 0.24 : 0.12),
                ),
              ),
              Positioned(
                bottom: 206,
                left: 16,
                child: _SoftGlowOrb(
                  size: 104,
                  blurSigma: 24,
                  color:
                      scheme.secondary.withValues(alpha: isLight ? 0.12 : 0.11),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BlurHighlight extends StatelessWidget {
  const _BlurHighlight({
    required this.width,
    required this.height,
    required this.angle,
    required this.blurSigma,
    required this.colorA,
    required this.colorB,
  });

  final double width;
  final double height;
  final double angle;
  final double blurSigma;
  final Color colorA;
  final Color colorB;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[colorA, colorB],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftGlowOrb extends StatelessWidget {
  const _SoftGlowOrb({
    required this.size,
    required this.blurSigma,
    required this.color,
  });

  final double size;
  final double blurSigma;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
