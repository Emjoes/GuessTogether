import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final appVersionProvider = FutureProvider<AppVersionInfo>((ref) async {
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return AppVersionInfo.fromPackageInfo(packageInfo);
});

class AppVersionInfo {
  const AppVersionInfo({
    required this.current,
    required this.buildNumber,
  });

  factory AppVersionInfo.fromPackageInfo(PackageInfo packageInfo) {
    return AppVersionInfo(
      current: _normalizedVersion(packageInfo.version),
      buildNumber: int.tryParse(packageInfo.buildNumber) ?? 0,
    );
  }

  final String current;
  final int buildNumber;

  String get display => current;
}

class AppVersion {
  AppVersion._();

  static bool isAtLeast(String currentVersion, String requiredVersion) {
    return compare(currentVersion, requiredVersion) >= 0;
  }

  static int compare(String left, String right) {
    final List<int> leftParts = _numericParts(left);
    final List<int> rightParts = _numericParts(right);
    final int maxLength = math.max(leftParts.length, rightParts.length);
    for (int index = 0; index < maxLength; index++) {
      final int leftPart = index < leftParts.length ? leftParts[index] : 0;
      final int rightPart = index < rightParts.length ? rightParts[index] : 0;
      if (leftPart != rightPart) {
        return leftPart.compareTo(rightPart);
      }
    }
    return 0;
  }

  static List<int> _numericParts(String version) {
    final String trimmed = version.trim();
    if (trimmed.isEmpty) {
      return const <int>[0];
    }

    final List<int> parts = trimmed
        .split(RegExp(r'[^0-9]+'))
        .where((String segment) => segment.isNotEmpty)
        .map((String segment) => int.tryParse(segment) ?? 0)
        .toList(growable: false);
    return parts.isEmpty ? const <int>[0] : parts;
  }
}

String _normalizedVersion(String version) {
  final String trimmed = version.trim();
  return trimmed.isEmpty ? '0.0.0' : trimmed;
}
