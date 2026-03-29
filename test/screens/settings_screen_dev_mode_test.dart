import 'package:appmobile/models/job.dart';
import 'package:appmobile/repositories/job_repository.dart';
import 'package:appmobile/screens/settings_screen.dart';
import 'package:appmobile/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ImmediateJobRepository implements JobRepository {
  @override
  Future<List<Job>> getJobs() async => <Job>[];
}

void main() {
  testWidgets('7 taps enable developer tools card', (tester) async {
    SharedPreferences.setMockInitialValues({});

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

    final versionText = find.text('Versão 1.0.0+1');
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
