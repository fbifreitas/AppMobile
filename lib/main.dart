import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'branding/brand_provider.dart';
import 'branding/kaptur_brand.dart';
import 'branding/remote/brand_config_resolver.dart';
import 'branding/remote/remote_brand_overrides.dart';
import 'branding/resolved_brand_config.dart';
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
import 'l10n/app_strings.dart';

/// Entrypoint padrão — usa flavor Kaptur.
/// Para outros flavors, use main_kaptur.dart ou main_compass.dart.
void main() => _runWithBrand(
      config: BrandConfigResolver.resolve(
        kapturManifest,
        overrides: RemoteBrandOverrides.empty,
      ),
    );

void _runWithBrand({required ResolvedBrandConfig config}) {
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
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        return const OnboardingScreen();
      case AppAuthStatus.awaitingApproval:
        return const AwaitingApprovalScreen();
      case AppAuthStatus.active:
        return const HomeScreen();
    }
  }
}
