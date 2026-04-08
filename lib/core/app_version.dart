class AppVersion {
  AppVersion._();

  // Human-facing version shown in the app UI.
  static const String display =
      String.fromEnvironment('APP_VERSION', defaultValue: '1.00');
}
