import 'package:appmobile/models/job.dart';
import 'package:appmobile/repositories/job_repository.dart';
import 'package:appmobile/repositories/preferences_repository.dart';
import 'package:appmobile/screens/onboarding_screen.dart';
import 'package:appmobile/state/app_state.dart';
import 'package:appmobile/state/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _ImmediateJobRepository implements JobRepository {
  @override
  Future<List<Job>> getJobs() async => <Job>[];
}

class _MemoryPreferencesRepository implements PreferencesRepository {
  final Map<String, Object?> _store = <String, Object?>{};

  @override
  Future<bool?> getBool(String key) async => _store[key] as bool?;

  @override
  Future<String?> getString(String key) async => _store[key] as String?;

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _store[key] = value;
  }

  @override
  Future<void> setString(String key, String value) async {
    _store[key] = value;
  }
}

void main() {
  Future<void> pumpOnboarding(WidgetTester tester) async {
    final preferences = _MemoryPreferencesRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AppState(_ImmediateJobRepository(), preferences),
          ),
          ChangeNotifierProvider(create: (_) => AuthState(preferences)),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('onboarding starts directly in PJ flow', (tester) async {
    await pumpOnboarding(tester);

    expect(find.text('Cadastro PJ'), findsOneWidget);
    expect(find.text('Qual é o seu vínculo?'), findsNothing);
    expect(find.byKey(const Key('onboarding_cnpj_field')), findsOneWidget);
    expect(find.byKey(const Key('tipo_clt')), findsNothing);
    expect(find.byKey(const Key('tipo_pj')), findsNothing);
  });

  testWidgets('onboarding validates CNPJ before advancing', (tester) async {
    await pumpOnboarding(tester);

    await tester.enterText(
      find.byKey(const Key('onboarding_nome_field')),
      'Fornecedor QA',
    );
    await tester.enterText(
      find.byKey(const Key('onboarding_cnpj_field')),
      '11111111111111',
    );

    await tester.tap(find.byKey(const Key('onboarding_next_button')));
    await tester.pumpAndSettle();

    expect(find.text('CNPJ inválido'), findsOneWidget);
    expect(find.byKey(const Key('onboarding_banco_field')), findsNothing);
  });
}
