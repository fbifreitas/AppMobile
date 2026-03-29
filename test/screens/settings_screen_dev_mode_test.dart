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

  testWidgets('7 taps enable developer tools card', (tester) async {
    final appState = AppState(_ImmediateJobRepository());

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => appState,
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final versionText = find.text('v1.0.97+1');
    for (var i = 0; i < 7; i++) {
      await tester.tap(versionText);
      await tester.pump();
    }

    await tester.pumpAndSettle();

    expect(find.text('Ferramentas do desenvolvedor'), findsOneWidget);
    expect(find.text('Habilitar ferramenta do desenvolvedor'), findsOneWidget);
    expect(appState.developerModeEnabled, isTrue);
    expect(appState.developerToolsUnlocked, isTrue);
  });

  testWidgets('disabling developer tools hides card and contents',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'developer_tools_unlocked': true,
      'developer_mode_enabled': true,
      'developer_allow_far_start': false,
    });
    await _mockPackageInfo();

    final appState = AppState(_ImmediateJobRepository());

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => appState,
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ferramentas do desenvolvedor'), findsOneWidget);
    expect(find.text('Habilitar ferramenta do desenvolvedor'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(find.text('Ferramentas do desenvolvedor'), findsNothing);
    expect(find.text('Habilitar ferramenta do desenvolvedor'), findsNothing);
    expect(find.text('Permitir iniciar longe do local'), findsNothing);
    expect(appState.developerModeEnabled, isFalse);
    expect(appState.developerToolsUnlocked, isFalse);
  });
}
