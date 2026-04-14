import '../config/checkin_step2_config.dart';
import '../state/app_state.dart';

class InspectionRuntimeContextService {
  const InspectionRuntimeContextService();

  static const InspectionRuntimeContextService instance =
      InspectionRuntimeContextService();

  TipoImovel resolveTipoImovel(String rawTipoImovel) {
    final normalized = rawTipoImovel.split('?').first.trim();
    return TipoImovelExtension.fromString(normalized);
  }

  AssetType resolveAssetType(String rawAssetType) {
    return resolveTipoImovel(rawAssetType);
  }

  String? resolveSubtipoImovel({
    required AppState appState,
    required String fallbackTipoImovel,
  }) {
    final direct =
        appState.step1Payload['assetSubtype'] ??
        appState.step1Payload['subtipoImovel'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct.trim();
    }

    final rawStep1 = appState.inspectionRecoveryPayload['step1'];
    if (rawStep1 is Map) {
      final restored = rawStep1['assetSubtype'] ?? rawStep1['subtipoImovel'];
      if (restored is String && restored.trim().isNotEmpty) {
        return restored.trim();
      }
    }

    return fallbackTipoImovel.trim().isEmpty ? null : fallbackTipoImovel.trim();
  }

  String? resolveAssetSubtype({
    required AppState appState,
    required String fallbackAssetType,
  }) {
    return resolveSubtipoImovel(
      appState: appState,
      fallbackTipoImovel: fallbackAssetType,
    );
  }
}
