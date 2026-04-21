import 'package:flutter/material.dart';

import '../models/flow_selection.dart';
import '../models/overlay_camera_capture_result.dart';
import '../services/inspection_camera_entry_policy_service.dart';
import '../services/inspection_flow_coordinator.dart';
import '../state/app_state.dart';

class InspectionCheckinCameraUseCase {
  const InspectionCheckinCameraUseCase({
    this.cameraEntryPolicy = InspectionCameraEntryPolicyService.instance,
  });

  static const InspectionCheckinCameraUseCase instance =
      InspectionCheckinCameraUseCase();

  final InspectionCameraEntryPolicyService cameraEntryPolicy;

  Future<void> openFromStep1(
    BuildContext context, {
    required InspectionFlowCoordinator flowCoordinator,
    required AppState appState,
    required String tipoImovel,
    required String subtipoImovel,
    required FlowSelection initialSelection,
  }) async {
    final currentJobPlan = appState.jobAtual?.smartExecutionPlan;
    if (appState.currentExecutionPlan == null && currentJobPlan != null) {
      appState.currentExecutionPlan = currentJobPlan;
    }

    await flowCoordinator.openOverlayCamera(
      context,
      request: cameraEntryPolicy.buildRequest(
        source: InspectionCameraEntrySource.step1,
        title: 'COLETA',
        tipoImovel: tipoImovel,
        subtipoImovel: subtipoImovel,
        explicitSelection: initialSelection,
        step1Payload: appState.step1Payload,
        currentCaptures: const <OverlayCameraCaptureResult>[],
        inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
      ),
    );
  }
}
