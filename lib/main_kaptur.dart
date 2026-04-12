import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'branding/brand_provider.dart';
import 'branding/kaptur_brand.dart';
import 'branding/remote/brand_config_resolver.dart';
import 'branding/remote/remote_brand_overrides.dart';
import 'repositories/fake_job_repository.dart';
import 'repositories/preferences_repository.dart';
import 'screens/awaiting_approval_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/permissions_onboarding_screen.dart';
import 'state/app_state.dart';
import 'state/auth_state.dart';
import 'state/inspection_state.dart';
import 'theme/app_theme.dart';

/// Entrypoint do flavor **Kaptur**.
///
/// ## Android
/// Referenciado em android/app/build.gradle.kts via:
///   flavorDimensions "brand"
///   productFlavors { kaptur { ... } }
/// e apontado pelo flutter tool com --flavor kaptur --target lib/main_kaptur.dart
///
/// ## iOS
/// Referenciado no scheme Xcode "kaptur" com argumento:
///   --dart-define=FLUTTER_TARGET=lib/main_kaptur.dart
/// Ver docs/04-engineering/iOS_FLAVOR_SETUP_GUIDE.md para procedimento completo.
void main() {
  // TODO: Substituir RemoteBrandOverrides.empty por fetch real de config remota
  // quando o backend de configuração estiver disponível.
  final config = BrandConfigResolver.resolve(
    kapturManifest,
    overrides: RemoteBrandOverrides.empty,
  );

  runApp(
    BrandProvider(
      config: config,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AppState(
              FakeJobRepository(),
              const SharedPreferencesRepository(),
              null,
              false,
            ),
          ),
          ChangeNotifierProvider(create: (_) => InspectionState()),
          ChangeNotifierProvider(
            create: (_) => AuthState(const SharedPreferencesRepository()),
          ),
        ],
        child: const _KapturApp(),
      ),
    ),
  );
}

class _KapturApp extends StatelessWidget {
  const _KapturApp();

  @override
  Widget build(BuildContext context) {
    final config = BrandProvider.configOf(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: config.appName,
      theme: AppTheme.fromConfig(config),
      home: const _AppEntryPoint(),
    );
  }
}

class _AppEntryPoint extends StatelessWidget {
  const _AppEntryPoint();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (auth.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.requiresPermissionsOnboarding) {
      return const PermissionsOnboardingScreen();
    }
    switch (auth.status) {
      case AppAuthStatus.unauthenticated:
        return const LoginScreen();
      case AppAuthStatus.onboarding:
        return const OnboardingScreen();
      case AppAuthStatus.awaitingApproval:
        return const AwaitingApprovalScreen();
      case AppAuthStatus.active:
        return const HomeScreen();
    }
  }
}
