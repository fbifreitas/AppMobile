import 'package:appmobile/branding/brand_provider.dart';
import 'package:appmobile/branding/compass_brand.dart';
import 'package:appmobile/branding/remote/brand_config_resolver.dart';
import 'package:appmobile/branding/remote/remote_brand_overrides.dart';
import 'package:appmobile/repositories/preferences_repository.dart';
import 'package:appmobile/screens/login_screen.dart';
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

class _HandshakeFailureGateway implements MobileAuthGateway {
  @override
  bool get isConfigured => true;

  @override
  Future<MobileAuthSession> login({
    required String tenantId,
    required String email,
    required String password,
    required String deviceInfo,
  }) async {
    throw const MobileAuthException(
      'Nao foi possivel estabelecer conexao segura com o servidor. Tente novamente em alguns instantes.',
      502,
    );
  }

  @override
  Future<MobileAuthTokens> refresh({required String refreshToken}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout({required String refreshToken}) async {}
}

void main() {
  testWidgets('shows friendly message when secure connection fails', (
    tester,
  ) async {
    final authState = AuthState(
      _MemoryPreferencesRepository(),
      _HandshakeFailureGateway(),
      'tenant-compass',
    );
    final config = BrandConfigResolver.resolve(
      compassManifest,
      overrides: RemoteBrandOverrides.empty,
    );

    await tester.pumpWidget(
      BrandProvider(
        config: config,
        child: ChangeNotifierProvider<AuthState>.value(
          value: authState,
          child: const MaterialApp(home: LoginScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'joao.compass@local.test',
    );
    await tester.enterText(
      find.byKey(const Key('login_senha_field')),
      'Compass@123',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text(
        'Nao foi possivel estabelecer conexao segura com o servidor. Tente novamente em alguns instantes.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('TLSV1_ALERT_UNRECOGNIZED_NAME'),
      findsNothing,
    );
  });
}
