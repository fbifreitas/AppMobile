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
        currentValue: 'myapp',
        suggestedValue: 'appmobile',
        description: 'Padronizar o nome do pacote para uma identidade coerente com o produto.',
      ),
      ReleaseIdentityItem(
        scope: 'android_label',
        currentValue: 'myapp',
        suggestedValue: '@string/app_name (flavor-specific)',
        description:
            'Label Android resolvido por flavor: kaptur → "Kaptur", compass → "Compass Avaliações". '
            'Gerenciado em build.gradle.kts via resValue.',
      ),
      ReleaseIdentityItem(
        scope: 'ios_bundle_display_name',
        currentValue: 'Myapp',
        suggestedValue: 'Flavor-specific (ver iOS_FLAVOR_SETUP_GUIDE.md)',
        description:
            'CFBundleDisplayName resolvido por scheme iOS. '
            'Kaptur → "Kaptur"; Compass → "Compass Avaliações".',
      ),
    ];
  }
}
