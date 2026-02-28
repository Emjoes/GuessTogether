import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BackShortcutScope extends StatefulWidget {
  const BackShortcutScope({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<BackShortcutScope> createState() => _BackShortcutScopeState();
}

class _BackShortcutScopeState extends State<BackShortcutScope> {
  bool _handleHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }

    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) {
      return false;
    }

    final NavigatorState navigator = Navigator.of(context);
    unawaited(navigator.maybePop());
    return true;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
