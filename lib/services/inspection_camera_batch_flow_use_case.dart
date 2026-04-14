import '../models/inspection_recovery_stage.dart';
import '../models/overlay_camera_capture_result.dart';
import '../state/app_state.dart';
import 'inspection_camera_batch_service.dart';
import 'inspection_capture_recovery_adapter.dart';
import 'inspection_recovery_stage_service.dart';

class InspectionCameraBatchFlowUseCase {
  InspectionCameraBatchFlowUseCase({
    InspectionCameraBatchService? batchService,
    InspectionCaptureRecoveryAdapter? captureRecoveryAdapter,
    InspectionRecoveryStageService? recoveryStageService,
  }) : batchService = batchService ?? InspectionCameraBatchService.instance,
       captureRecoveryAdapter =
           captureRecoveryAdapter ?? InspectionCaptureRecoveryAdapter.instance,
       recoveryStageService =
           recoveryStageService ?? InspectionRecoveryStageService.instance;

  static final InspectionCameraBatchFlowUseCase instance =
      InspectionCameraBatchFlowUseCase();

  final InspectionCameraBatchService batchService;
  final InspectionCaptureRecoveryAdapter captureRecoveryAdapter;
  final InspectionRecoveryStageService recoveryStageService;

  bool hasPersistedPhotos(AppState appState) {
    return captureRecoveryAdapter.hasPersistedPhotos(
      step2Payload: appState.step2Payload,
      inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
    );
  }

  List<OverlayCameraCaptureResult> mergeReviewCaptures({
    required List<OverlayCameraCaptureResult> currentCaptures,
    required AppState appState,
  }) {
    return captureRecoveryAdapter.mergeReviewCaptures(
      currentCaptures: currentCaptures,
      inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
    );
  }

  Future<void> syncStep2DraftFromBatchCaptures({
    required AppState appState,
    required List<OverlayCameraCaptureResult> captures,
    required String tipoImovel,
    required bool cameFromCheckinStep1,
  }) async {
    if (!cameFromCheckinStep1 || captures.isEmpty) {
      return;
    }

    final mergedStep2 = batchService.buildStep2PayloadFromCaptures(
      existingStep2Payload: appState.step2Payload,
      inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
      captures: captures,
      tipoImovel: tipoImovel,
    );

    final draft = appState.inspectionRecoveryDraft;
    final jobId = appState.jobAtual?.id;
    if (jobId == null) {
      return;
    }
    final stage =
        draft?.resolvedStage == InspectionRecoveryStageId.checkinStep2
            ? InspectionRecoveryStageId.checkinStep2
            : InspectionRecoveryStageId.checkinStep1;

    if (stage == InspectionRecoveryStageId.checkinStep2) {
      await appState.setInspectionRecoverySnapshot(
        recoveryStageService.checkinStep2(
          jobId: jobId,
          inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
          step1Payload: appState.step1Payload,
          step2Payload: mergedStep2,
        ),
      );
      return;
    }

    await appState.setInspectionRecoverySnapshot(
      recoveryStageService.checkinStep1(
        jobId: jobId,
        inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
        step1Payload: appState.step1Payload,
        step2Payload: mergedStep2,
      ),
    );
  }
}
