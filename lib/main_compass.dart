import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'branding/brand_provider.dart';
import 'branding/compass_brand.dart';
import 'branding/remote/brand_config_resolver.dart';
import 'branding/remote/remote_brand_overrides.dart';
import 'repositories/backend_job_repository.dart';
import 'repositories/fake_job_repository.dart';
import 'repositories/preferences_repository.dart';
import 'screens/awaiting_approval_screen.dart';
import 'screens/compass_first_access_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/permissions_onboarding_screen.dart';
import 'state/app_state.dart';
import 'state/auth_state.dart';
import 'state/inspection_state.dart';
import 'theme/app_theme.dart';
import 'l10n/app_strings.dart';

/// Entrypoint do flavor **Compass Avaliações**.
///
/// ## Android
/// Referenciado em android/app/build.gradle.kts via:
///   productFlavors { compass { ... } }
/// e apontado pelo flutter tool com --flavor compass --target lib/main_compass.dart
///
/// ## iOS
/// Referenciado no scheme Xcode "compass" com argumento:
///   --dart-define=FLUTTER_TARGET=lib/main_compass.dart
/// Ver docs/04-engineering/iOS_FLAVOR_SETUP_GUIDE.md para procedimento completo.
void main() {
  final config = BrandConfigResolver.resolve(
    compassManifest,
    overrides: RemoteBrandOverrides.empty,
  );

  runApp(
    BrandProvider(
      config: config,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create:
                (_) => AppState(
                  BackendJobRepository(fallbackRepository: FakeJobRepository()),
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
        child: const _CompassApp(),
      ),
    ),
  );
}

class _CompassApp extends StatelessWidget {
  const _CompassApp();

  @override
  Widget build(BuildContext context) {
    final config = BrandProvider.configOf(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: config.appName,
      theme: AppTheme.fromConfig(config),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: AppStrings.localizationsDelegates,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('pt');
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) {
            return supported;
          }
        }
        return const Locale('pt');
      },
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
        return const CompassFirstAccessScreen();
      case AppAuthStatus.awaitingApproval:
        return const AwaitingApprovalScreen();
      case AppAuthStatus.active:
        return const HomeScreen();
    }
  }
}
