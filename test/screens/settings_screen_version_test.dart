import 'package:appmobile/models/job.dart';
import 'package:appmobile/repositories/job_repository.dart';
import 'package:appmobile/screens/settings_screen.dart';
import 'package:appmobile/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const MethodChannel _kPackageInfoChannel = MethodChannel('dev.fluttercommunity.plus/package_info');

Future<void> _mockPackageInfo({
  String version = '1.0.97',
  String buildNumber = '1',
}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    _kPackageInfoChannel,
    (call) async {
      if (call.method == 'getAll') {
        return {
          'appName': 'App Mobile',
          'packageName': 'appmobile',
          'version': version,
          'buildNumber': buildNumber,
          'buildSignature': '',
        };
      }
      return null;
    },
  );
}

class _ImmediateJobRepository implements JobRepository {
  @override
  Future<List<Job>> getJobs() async => <Job>[];
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await _mockPackageInfo();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_kPackageInfoChannel, null);
  });

  testWidgets('SettingsScreen displays dynamic version from package_info_plus',
      (tester) async {
    final appState = AppState(_ImmediateJobRepository());

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => appState,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('v1.0.97+1'), findsOneWidget);
  });
}
