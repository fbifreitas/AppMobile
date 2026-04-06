import 'package:geolocator/geolocator.dart';

import '../config/checkin_step2_config.dart';
import '../models/overlay_camera_capture_result.dart';
import 'checkin_dynamic_config_service.dart';
import 'inspection_environment_instance_service.dart';
import 'inspection_requirement_policy_service.dart';

class InspectionCameraBatchService {
  InspectionCameraBatchService({
    InspectionEnvironmentInstanceService? environmentInstanceService,
    CheckinDynamicConfigService? dynamicConfigService,
    InspectionRequirementPolicyService? requirementPolicy,
  }) : environmentInstanceService =
           environmentInstanceService ??
           InspectionEnvironmentInstanceService.instance,
       dynamicConfigService =
           dynamicConfigService ?? CheckinDynamicConfigService.instance,
       requirementPolicy =
           requirementPolicy ?? InspectionRequirementPolicyService.instance;

  static final InspectionCameraBatchService instance =
      InspectionCameraBatchService();

  final InspectionEnvironmentInstanceService environmentInstanceService;
  final CheckinDynamicConfigService dynamicConfigService;
  final InspectionRequirementPolicyService requirementPolicy;

  OverlayCameraCaptureResult buildCaptureResult({
    required String filePath,
    required String ambiente,
    required DateTime capturedAt,
    required Position position,
    String? macroLocal,
    String? elemento,
    String? material,
    String? estado,
    String? predictionSummary,
    String? contextSuggestionSummary,
  }) {
    final parsedAmbiente = environmentInstanceService.parse(ambiente);
    final usedSuggestion =
        (contextSuggestionSummary != null &&
            contextSuggestionSummary.trim().isNotEmpty) ||
        (predictionSummary != null && predictionSummary.trim().isNotEmpty);

    return OverlayCameraCaptureResult(
      filePath: filePath,
      macroLocal: macroLocal,
      ambiente: ambiente,
      ambienteBase: environmentInstanceService.baseLabelOf(ambiente),
      ambienteInstanceIndex: parsedAmbiente.instanceIndex,
      elemento: elemento,
      material: material,
      estado: estado,
      capturedAt: capturedAt,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      usedSuggestion: usedSuggestion,
      suggestionSummary: predictionSummary ?? contextSuggestionSummary,
    );
  }

  Map<String, dynamic> buildStep2PayloadFromCaptures({
    required Map<String, dynamic> existingStep2Payload,
    required Map<String, dynamic> inspectionRecoveryPayload,
    required List<OverlayCameraCaptureResult> captures,
    required String tipoImovel,
  }) {
    final tipo = TipoImovelExtension.fromString(tipoImovel);
    var model = dynamicConfigService.restoreStep2Model(
      tipo: tipo,
      step2Payload: existingStep2Payload,
    );
    final config = dynamicConfigService.resolveStoredStep2Config(
      tipo: tipo,
      inspectionRecoveryPayload: inspectionRecoveryPayload,
    );

    for (final campo in config.camposFotos) {
      final matchedCapture = requirementPolicy.findMatchingCapture(
        captures: captures,
        field: campo,
      );

      if (matchedCapture != null) {
        model = model.setPhoto(
          fieldId: campo.id,
          titulo: campo.titulo,
          imagePath: matchedCapture.filePath,
          geoPoint: matchedCapture.toGeoPointData(),
        );
      }
    }

    return model.toMap();
  }
}
