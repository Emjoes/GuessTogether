import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guesstogether/core/app_version.dart';
import 'package:guesstogether/data/api/app_backend_api.dart';
import 'package:guesstogether/data/api/backend_models.dart';
import 'package:guesstogether/features/session/app_session_controller.dart';

final appVersionCheckApiProvider = Provider<AppBackendApi>((ref) {
  final String baseHttpUrl = ref.watch(backendBaseHttpUrlProvider);
  final String baseWsUrl = ref.watch(backendBaseWsUrlProvider);
  return HttpAppBackendApi(
    baseHttpUrl: baseHttpUrl,
    baseWsUrl: baseWsUrl,
  );
});

final appVersionGateProvider = FutureProvider<AppVersionGateState>((ref) async {
  final AppBackendApi api = ref.watch(appVersionCheckApiProvider);
  try {
    final AppVersionStatus remote = await api.loadAppVersionStatus();
    return AppVersionGateState.fromRemote(remote);
  } catch (_) {
    return const AppVersionGateState(
      currentVersion: AppVersion.current,
      latestVersion: AppVersion.current,
      minimumSupportedVersion: AppVersion.current,
      isSupported: true,
      checkedRemotely: false,
    );
  }
});

class AppVersionGateState {
  const AppVersionGateState({
    required this.currentVersion,
    required this.latestVersion,
    required this.minimumSupportedVersion,
    required this.isSupported,
    required this.checkedRemotely,
  });

  factory AppVersionGateState.fromRemote(AppVersionStatus remote) {
    final String latestVersion = _normalizedVersion(
      remote.latestVersion,
      fallback: AppVersion.current,
    );
    final String minimumSupportedVersion = _normalizedVersion(
      remote.minimumSupportedVersion,
      fallback: latestVersion,
    );
    return AppVersionGateState(
      currentVersion: AppVersion.current,
      latestVersion: latestVersion,
      minimumSupportedVersion: minimumSupportedVersion,
      isSupported: AppVersion.isAtLeast(minimumSupportedVersion),
      checkedRemotely: true,
    );
  }

  final String currentVersion;
  final String latestVersion;
  final String minimumSupportedVersion;
  final bool isSupported;
  final bool checkedRemotely;

  bool get requiresUpdate => !isSupported;

  static String _normalizedVersion(
    String version, {
    required String fallback,
  }) {
    final String trimmed = version.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}
