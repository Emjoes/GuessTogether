import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get isLoadingDebugGateSupported =>
    kDebugMode && !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

class LoadingDebugGate extends ChangeNotifier {
  LoadingDebugGate._();

  static final LoadingDebugGate instance = LoadingDebugGate._();

  bool _enabled = false;
  int _releaseSignal = 0;

  bool get enabled => isLoadingDebugGateSupported && _enabled;

  void toggle() {
    if (!isLoadingDebugGateSupported) {
      return;
    }

    if (_enabled) {
      _enabled = false;
      _releaseSignal += 1;
    } else {
      _enabled = true;
    }
    notifyListeners();
  }

  void releaseOnce() {
    if (!enabled) {
      return;
    }
    _releaseSignal += 1;
    notifyListeners();
  }

  Future<void> waitIfNeeded() async {
    if (!enabled) {
      return;
    }

    final int startSignal = _releaseSignal;
    final Completer<void> completer = Completer<void>();
    late final VoidCallback listener;

    listener = () {
      if (!enabled || _releaseSignal != startSignal) {
        removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    };

    addListener(listener);
    listener();
    await completer.future;
  }

  Future<void> delayed(Duration duration) async {
    await Future<void>.delayed(duration);
    await waitIfNeeded();
  }
}

class LoadingDebugOverlay extends StatelessWidget {
  const LoadingDebugOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
