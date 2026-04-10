import 'package:appmobile/branding/brand_provider.dart';
import 'package:appmobile/branding/compass_brand.dart';
import 'package:appmobile/branding/remote/brand_config_resolver.dart';
import 'package:appmobile/branding/remote/remote_brand_overrides.dart';
import 'package:appmobile/repositories/preferences_repository.dart';
import 'package:appmobile/screens/compass_first_access_screen.dart';
import 'package:appmobile/services/mobile_auth_service.dart';
import 'package:appmobile/state/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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

class _FakeFirstAccessService extends MobileBackendAuthService {
  const _FakeFirstAccessService();

  @override
  Future<MobileFirstAccessChallenge> startFirstAccess({
    required String tenantId,
    required String cpf,
    required String birthDate,
    required String identifier,
  }) async {
    expect(tenantId, 'tenant-compass');
    expect(cpf, '123.456.789-01');
    expect(birthDate, '1990-05-20');
    expect(identifier, 'COMPASS-001');
    return const MobileFirstAccessChallenge(
      challengeId: 'challenge-1',
      deliveryHint: 'Codigo enviado ao telefone cadastrado final 1234.',
      expiresInSeconds: 600,
    );
  }

  @override
  Future<MobileAuthSession> completeFirstAccess({
    required String tenantId,
    required String challengeId,
    required String otp,
    required String newPassword,
    required String deviceInfo,
  }) async {
    expect(challengeId, 'challenge-1');
    expect(otp, '123456');
    expect(newPassword, 'Compass@123');
    return const MobileAuthSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      tokenType: 'Bearer',
      expiresInSeconds: 900,
      userId: 42,
      tenantId: 'tenant-compass',
      email: 'operador@compass.test',
      userStatus: 'APPROVED',
      membershipRole: 'OPERATOR',
      membershipStatus: 'ACTIVE',
      permissions: <String>['jobs:read'],
    );
  }
}

void main() {
  testWidgets('activates Compass provisioned user through OTP first access', (
    tester,
  ) async {
    final prefs = _MemoryPreferencesRepository();
    final authState = AuthState(prefs);
    final config = BrandConfigResolver.resolve(
      compassManifest,
      overrides: RemoteBrandOverrides.empty,
    );

    await tester.pumpWidget(
      BrandProvider(
        config: config,
        child: ChangeNotifierProvider<AuthState>.value(
          value: authState,
          child: const MaterialApp(
            home: CompassFirstAccessScreen(
              authService: _FakeFirstAccessService(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('compass_first_access_cpf_field')),
      '123.456.789-01',
    );
    await tester.enterText(
      find.byKey(const Key('compass_first_access_birth_date_field')),
      '20/05/1990',
    );
    await tester.enterText(
      find.byKey(const Key('compass_first_access_identifier_field')),
      'COMPASS-001',
    );
    await tester.tap(find.byKey(const Key('compass_first_access_start_button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Codigo enviado ao telefone cadastrado final 1234.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('compass_first_access_otp_field')),
      '123456',
    );
    await tester.enterText(
      find.byKey(const Key('compass_first_access_password_field')),
      'Compass@123',
    );
    await tester.tap(
      find.byKey(const Key('compass_first_access_complete_button')),
    );
    await tester.pumpAndSettle();

    expect(authState.status, AppAuthStatus.active);
    expect(await prefs.getString('auth_user_email'), 'operador@compass.test');
    expect(await prefs.getString('auth_tenant_id'), 'tenant-compass');
  });
}
