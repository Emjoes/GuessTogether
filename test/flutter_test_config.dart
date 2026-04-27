import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  PackageInfo.setMockInitialValues(
    appName: 'Guess Together',
    packageName: 'com.example.guesstogether',
    version: '1.0.1',
    buildNumber: '101',
    buildSignature: '',
  );
  await testMain();
}
