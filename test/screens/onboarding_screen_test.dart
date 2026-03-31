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
  Future<_MemoryPreferencesRepository> pumpOnboarding(
    WidgetTester tester, {
    _MemoryPreferencesRepository? preferences,
  }) async {
    final prefs = preferences ?? _MemoryPreferencesRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AppState(_ImmediateJobRepository(), prefs),
          ),
          ChangeNotifierProvider(create: (_) => AuthState(prefs)),
        ],
        child: MaterialApp(home: const OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return prefs;
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

  testWidgets('onboarding conclui com dados validos de PJ', (tester) async {
    final prefs = await pumpOnboarding(tester);

    await tester.enterText(
      find.byKey(const Key('onboarding_nome_field')),
      'ACM',
    );
    await tester.enterText(
      find.byKey(const Key('onboarding_cnpj_field')),
      '18.914.249/0001-78',
    );

    await tester.tap(find.byKey(const Key('onboarding_next_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('onboarding_banco_field')),
      '341',
    );
    await tester.enterText(
      find.byKey(const Key('onboarding_agencia_field')),
      '2965',
    );
    await tester.enterText(
      find.byKey(const Key('onboarding_conta_field')),
      '055508',
    );

    await tester.tap(find.byKey(const Key('onboarding_next_button')));
    await tester.pumpAndSettle();

    expect(
      await prefs.getString('auth_status'),
      AppAuthStatus.awaitingApproval.name,
    );
  });
}
