import 'dart:math' as math;

class AppVersion {
  AppVersion._();

  static const String current =
      String.fromEnvironment('APP_VERSION', defaultValue: '1.0.1');
  static const int buildNumber =
      int.fromEnvironment('APP_BUILD_NUMBER', defaultValue: 101);

  // Human-facing version shown in the app UI.
  static const String display = current;

  static bool isAtLeast(String requiredVersion) {
    return compare(current, requiredVersion) >= 0;
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
