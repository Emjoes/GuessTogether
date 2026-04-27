import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guesstogether/core/app_version.dart';
import 'package:guesstogether/core/l10n/app_locale.dart';
import 'package:guesstogether/data/api/app_backend_api.dart';
import 'package:guesstogether/data/api/backend_models.dart';
import 'package:guesstogether/features/session/app_session_controller.dart';

final appVersionCheckApiProvider = Provider<AppBackendApi>((ref) {
  final String baseHttpUrl = ref.watch(backendBaseHttpUrlProvider);
  final String baseWsUrl = ref.watch(backendBaseWsUrlProvider);
  final String languageCode =
      ref.watch(appLanguageProvider).locale.languageCode;
  return HttpAppBackendApi(
    baseHttpUrl: baseHttpUrl,
    baseWsUrl: baseWsUrl,
    languageCode: languageCode,
  );
});

final appVersionGateProvider = FutureProvider<AppVersionGateState>((ref) async {
  final AppBackendApi api = ref.watch(appVersionCheckApiProvider);
  final AppVersionInfo appVersion = await ref.watch(appVersionProvider.future);
  try {
    final AppVersionStatus remote = await api.loadAppVersionStatus();
    return AppVersionGateState.fromRemote(
      remote,
      currentVersion: appVersion.current,
    );
  } catch (_) {
    return AppVersionGateState(
      currentVersion: appVersion.current,
      latestVersion: appVersion.current,
      minimumSupportedVersion: appVersion.current,
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

  factory AppVersionGateState.fromRemote(
    AppVersionStatus remote, {
    required String currentVersion,
  }) {
    final String latestVersion = _normalizedVersion(
      remote.latestVersion,
      fallback: currentVersion,
    );
    final String minimumSupportedVersion = _normalizedVersion(
      remote.minimumSupportedVersion,
      fallback: latestVersion,
    );
    return AppVersionGateState(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      minimumSupportedVersion: minimumSupportedVersion,
      isSupported: AppVersion.isAtLeast(currentVersion, minimumSupportedVersion),
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
