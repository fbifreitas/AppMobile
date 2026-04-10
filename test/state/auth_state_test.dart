import 'package:appmobile/repositories/preferences_repository.dart';
import 'package:appmobile/state/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

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
  Future<void> waitAuthReady(AuthState authState) async {
    while (authState.loading) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  test('logout clears full mock session data', () async {
    final repo = _MemoryPreferencesRepository();
    final authState = AuthState(repo);
    await waitAuthReady(authState);

    await authState.login('qa@empresa.com');
    await authState.completeOnboarding(
      nome: 'Usuario QA',
      tipo: 'PJ',
      cnpj: '11222333000181',
    );
    await authState.completePermissionsOnboarding();

    await authState.logout();

    expect(authState.status, AppAuthStatus.unauthenticated);
    expect(authState.userEmail, isNull);
    expect(authState.userNome, isNull);
    expect(authState.userTipo, isNull);
    expect(authState.userCpf, isNull);
    expect(authState.userCnpj, isNull);
    expect(authState.permissionsOnboardingCompleted, isFalse);
  });

  test('reset onboarding keeps login and returns flow to onboarding', () async {
    final repo = _MemoryPreferencesRepository();
    final authState = AuthState(repo);
    await waitAuthReady(authState);

    await authState.login('qa@empresa.com');
    await authState.completeOnboarding(
      nome: 'Usuario QA',
      tipo: 'PJ',
      cnpj: '11222333000181',
    );
    await authState.completePermissionsOnboarding();

    await authState.resetOnboardingForMock();

    expect(authState.status, AppAuthStatus.onboarding);
    expect(authState.userEmail, 'qa@empresa.com');
    expect(authState.userNome, isNull);
    expect(authState.userTipo, isNull);
    expect(authState.userCnpj, isNull);
    expect(authState.permissionsOnboardingCompleted, isFalse);
  });

  test('permissions onboarding can be completed and persisted', () async {
    final repo = _MemoryPreferencesRepository();
    final authState = AuthState(repo);
    await waitAuthReady(authState);

    await authState.login('qa@empresa.com');
    await authState.completeOnboarding(
      nome: 'Usuario QA',
      tipo: 'PJ',
      cnpj: '11222333000181',
    );
    await authState.activateAccount();

    expect(authState.permissionsOnboardingCompleted, isFalse);

    await authState.completePermissionsOnboarding();

    expect(authState.permissionsOnboardingCompleted, isTrue);
  });

  test('does not require permissions onboarding before login', () async {
    final repo = _MemoryPreferencesRepository();
    final authState = AuthState(repo);
    await waitAuthReady(authState);

    expect(authState.status, AppAuthStatus.unauthenticated);
    expect(authState.permissionsOnboardingCompleted, isFalse);
    expect(authState.requiresPermissionsOnboarding, isFalse);
  });

  test(
    'does not require permissions onboarding while awaiting approval',
    () async {
      final repo = _MemoryPreferencesRepository();
      final authState = AuthState(repo);
      await waitAuthReady(authState);

      await authState.login('qa@empresa.com');
      await authState.completeOnboarding(
        nome: 'Usuario QA',
        tipo: 'PJ',
        cnpj: '11222333000181',
      );

      expect(authState.status, AppAuthStatus.awaitingApproval);
      expect(authState.permissionsOnboardingCompleted, isFalse);
      expect(authState.requiresPermissionsOnboarding, isFalse);
    },
  );

  test(
    'requires permissions onboarding after provisioned user login',
    () async {
      final repo = _MemoryPreferencesRepository();
      await repo.setString('auth_user_nome', 'Usuario Provisionado');
      await repo.setString('auth_user_tipo', 'CLT');

      final authState = AuthState(repo);
      await waitAuthReady(authState);

      await authState.login('provisionado@compass.com');

      expect(authState.status, AppAuthStatus.active);
      expect(authState.permissionsOnboardingCompleted, isFalse);
      expect(authState.requiresPermissionsOnboarding, isTrue);
    },
  );
}
