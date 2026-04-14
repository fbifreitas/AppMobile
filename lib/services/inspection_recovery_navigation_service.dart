import '../config/checkin_step2_config.dart';
import '../models/checkin_step2_model.dart';
import '../models/inspection_camera_flow_request.dart';
import '../models/inspection_recovery_stage.dart';
import '../models/overlay_camera_capture_result.dart';
import '../services/checkin_dynamic_config_service.dart';
import '../services/inspection_recovery_route_service.dart';
import '../state/app_state.dart';

class InspectionRecoveryNavigationService {
  InspectionRecoveryNavigationService({
    CheckinDynamicConfigService? dynamicConfigService,
    InspectionRecoveryRouteService? recoveryRouteService,
  }) : dynamicConfigService =
           dynamicConfigService ?? CheckinDynamicConfigService.instance,
       recoveryRouteService =
           recoveryRouteService ?? InspectionRecoveryRouteService.instance;

  static final InspectionRecoveryNavigationService instance =
      InspectionRecoveryNavigationService();

  final CheckinDynamicConfigService dynamicConfigService;
  final InspectionRecoveryRouteService recoveryRouteService;

  Future<bool> resume({
    required AppState appState,
    required Future<void> Function(InspectionCameraFlowRequest request)
        openCamera,
    required void Function(
      String tipoImovel,
      CheckinStep2Model? initialData,
      List<OverlayCameraCaptureResult> captures,
    )
    openReview,
    required void Function(String tipoImovel, CheckinStep2Model? initialData)
    openCheckinStep2,
    required void Function() openCheckinStep1,
  }) async {
    final draft = appState.inspectionRecoveryDraft;
    if (draft == null) {
      return false;
    }

    switch (draft.resolvedStage) {
      case InspectionRecoveryStageId.camera:
        final request = recoveryRouteService.buildCameraRequestFromRecovery(
          appState.inspectionRecoveryPayload,
        );
        if (request == null) {
          return false;
        }
        await openCamera(request);
        return true;
      case InspectionRecoveryStageId.review:
        return _resumeReview(
          appState: appState,
          openReview: openReview,
        );
      case InspectionRecoveryStageId.checkinStep2:
        return _resumeCheckinStep2(
          appState: appState,
          openCheckinStep2: openCheckinStep2,
          openCheckinStep1: openCheckinStep1,
        );
      case InspectionRecoveryStageId.checkinStep1:
        openCheckinStep1();
        return true;
    }
  }

  Future<bool> _resumeReview(
    {
    required AppState appState,
    required void Function(
      String tipoImovel,
      CheckinStep2Model? initialData,
      List<OverlayCameraCaptureResult> captures,
    )
    openReview,
  }) async {
    final reviewPayload = appState.inspectionRecoveryPayload['review'];
    if (reviewPayload is! Map<String, dynamic>) {
      return false;
    }

    final tipoImovel = reviewPayload['tipoImovel'] as String?;
    if (tipoImovel == null || tipoImovel.trim().isEmpty) {
      return false;
    }

    final captures = <OverlayCameraCaptureResult>[];
    final rawCaptures = reviewPayload['captures'];
    if (rawCaptures is List) {
      for (final rawCapture in rawCaptures) {
        if (rawCapture is Map<String, dynamic>) {
          captures.add(OverlayCameraCaptureResult.fromMap(rawCapture));
        }
      }
    }

    final initialData =
        appState.step2Payload.isNotEmpty
            ? dynamicConfigService.restoreStep2Model(
              tipo: TipoImovelExtension.fromString(tipoImovel),
              step2Payload: appState.step2Payload,
            )
            : null;

    openReview(tipoImovel, initialData, captures);
    return true;
  }

  Future<bool> _resumeCheckinStep2(
    {
    required AppState appState,
    required void Function(String tipoImovel, CheckinStep2Model? initialData)
    openCheckinStep2,
    required void Function() openCheckinStep1,
  }) async {
    final tipoImovel = appState.step1Payload['tipoImovel'] as String?;
    final tipo = TipoImovelExtension.fromString(tipoImovel ?? 'Urbano');
    final step2Config = dynamicConfigService.resolveStoredStep2Config(
      tipo: tipo,
      inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
    );

    if (!step2Config.visivelNoFluxo) {
      openCheckinStep1();
      return true;
    }

    if (tipoImovel == null || tipoImovel.trim().isEmpty) {
      return false;
    }
    final initialData =
        appState.step2Payload.isNotEmpty
            ? dynamicConfigService.restoreStep2Model(
              tipo: tipo,
              step2Payload: appState.step2Payload,
            )
            : null;
    openCheckinStep2(tipoImovel, initialData);
    return true;
  }
}
