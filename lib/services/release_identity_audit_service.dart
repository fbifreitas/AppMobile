import '../models/release_identity_item.dart';

/// Audits release identity fields against expected canonical values.
///
/// NOTE (BL-074 — multi-brand): Since v1.2.46, the app uses productFlavors
/// (kaptur / compass). OS-level identity (app_name, bundle id) is now
/// flavor-specific and set at build time. The items below reflect the
/// pre-flavor baseline; individual flavor values are governed by
/// `android/app/build.gradle.kts` productFlavors and iOS scheme configs.
class ReleaseIdentityAuditService {
  const ReleaseIdentityAuditService();

  List<ReleaseIdentityItem> items() {
    return const <ReleaseIdentityItem>[
      ReleaseIdentityItem(
        scope: 'pubspec',
        currentValue: 'appmobile',
        suggestedValue: 'canonical',
        description:
            'Padronizar o nome do pacote para uma identidade coerente com o produto.',
      ),
      ReleaseIdentityItem(
        scope: 'android:label',
        currentValue: '@string/app_name by flavor',
        suggestedValue: 'canonical',
        description:
            'Label Android resolvido por flavor: kaptur → "Kaptur", compass → "Compass Avaliações". '
            'Gerenciado em build.gradle.kts via resValue.',
      ),
      ReleaseIdentityItem(
        scope: 'ios:bundle_display_name',
        currentValue: 'Flavor-specific target/scheme',
        suggestedValue: 'pending native project application',
        description:
            'CFBundleDisplayName resolvido por scheme iOS. '
            'Kaptur → "Kaptur"; Compass → "Compass Avaliações".',
      ),
      ReleaseIdentityItem(
        scope: 'android:kaptur',
        currentValue: 'com.kaptur.field / Kaptur / lib/main_kaptur.dart',
        suggestedValue: 'canonical',
        description:
            'Flavor Android Kaptur com applicationId, app_name e entrypoint proprios.',
      ),
      ReleaseIdentityItem(
        scope: 'android:compass',
        currentValue:
            'com.compass.avaliacoes / Compass Avaliacoes / lib/main_compass.dart',
        suggestedValue: 'canonical',
        description:
            'Flavor Android Compass com applicationId, app_name, entrypoint e artefato de CI separados.',
      ),
      ReleaseIdentityItem(
        scope: 'firebase:kaptur',
        currentValue: 'FIREBASE_APP_ID_ANDROID',
        suggestedValue: 'required',
        description:
            'Secret usado para distribuir o APK Kaptur no Firebase App Distribution.',
      ),
      ReleaseIdentityItem(
        scope: 'firebase:compass',
        currentValue: 'FIREBASE_APP_ID_ANDROID_COMPASS',
        suggestedValue: 'required for Compass',
        description:
            'Secret dedicado para distribuir o APK Compass sem reutilizar o app Firebase da Kaptur.',
      ),
    ];
  }
}
