import 'package:flutter/material.dart';

import 'package:guesstogether/widgets/app_backdrop.dart';

class MobileShell extends StatelessWidget {
  const MobileShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool fullBleed = constraints.maxWidth < 560;
        final double appWidth = fullBleed ? constraints.maxWidth : 430;
        final double radius = fullBleed ? 0 : 34;
        final EdgeInsets framePadding = fullBleed
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 18);

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isLight
                  ? const <Color>[
                      Color(0xFFFEFFFF),
                      Color(0xFFF8FCFF),
                    ]
                  : <Color>[
                      scheme.surface,
                      scheme.surface.withValues(alpha: 0.98),
                    ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: framePadding,
              child: SizedBox(
                width: appWidth,
                height: constraints.maxHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: fullBleed
                          ? null
                          : Border.all(
                              color: scheme.outline.withValues(alpha: 0.26),
                            ),
                      boxShadow: fullBleed
                          ? null
                          : <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.38),
                                blurRadius: 48,
                                offset: const Offset(0, 22),
                              ),
                            ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        const RepaintBoundary(child: AppBackdrop()),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
