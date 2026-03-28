import '../models/release_identity_item.dart';

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
        suggestedValue: 'App Mobile',
        description: 'Padronizar o label Android para o nome final do produto.',
      ),
      ReleaseIdentityItem(
        scope: 'ios_bundle_display_name',
        currentValue: 'Myapp',
        suggestedValue: 'App Mobile',
        description: 'Padronizar o nome exibido no iOS.',
      ),
    ];
  }
}
