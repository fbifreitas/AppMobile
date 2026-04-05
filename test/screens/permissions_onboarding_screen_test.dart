import 'package:appmobile/repositories/preferences_repository.dart';
import 'package:appmobile/screens/permissions_onboarding_screen.dart';
import 'package:appmobile/services/permissions_onboarding_service.dart';
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

class _FakePermissionsOnboardingService extends PermissionsOnboardingService {
  const _FakePermissionsOnboardingService(this._status);

  final PermissionsOnboardingStatus _status;

  @override
  Future<PermissionsOnboardingStatus> requestAll() async => _status;
}

void main() {
  Widget buildScreen({
    required AuthState authState,
    required PermissionsOnboardingService permissionsService,
  }) {
    return MaterialApp(
      home: ChangeNotifierProvider<AuthState>.value(
        value: authState,
        child: PermissionsOnboardingScreen(
          permissionsService: permissionsService,
        ),
      ),
    );
  }

  testWidgets('renders permissions action in bottom safe area', (
    tester,
  ) async {
    final authState = AuthState(_MemoryPreferencesRepository());

    await tester.pumpWidget(
      buildScreen(
        authState: authState,
        permissionsService: const _FakePermissionsOnboardingService(
          PermissionsOnboardingStatus(
            cameraGranted: false,
            locationGranted: false,
            microphoneGranted: false,
          ),
        ),
      ),
    );

    final safeAreas = tester.widgetList<SafeArea>(find.byType(SafeArea)).toList();
    final bottomBarSafeArea = safeAreas.where(
      (safeArea) =>
          safeArea.top == false &&
          safeArea.minimum == const EdgeInsets.fromLTRB(16, 8, 16, 16),
    );
    expect(bottomBarSafeArea.length, 1);
    expect(find.widgetWithText(FilledButton, 'Conceder permissoes e continuar'), findsOneWidget);
  });

  testWidgets('completes auth permissions onboarding when all are granted', (
    tester,
  ) async {
    final authState = AuthState(_MemoryPreferencesRepository());

    await tester.pumpWidget(
      buildScreen(
        authState: authState,
        permissionsService: const _FakePermissionsOnboardingService(
          PermissionsOnboardingStatus(
            cameraGranted: true,
            locationGranted: true,
            microphoneGranted: true,
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Conceder permissoes e continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(authState.permissionsOnboardingCompleted, isTrue);
    expect(
      find.text('Permissoes essenciais concedidas com sucesso.'),
      findsOneWidget,
    );
  });
}
