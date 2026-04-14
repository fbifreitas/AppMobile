import 'package:flutter/material.dart';

import '../config/checkin_step2_config.dart';
import '../models/flow_selection.dart';
import '../models/overlay_camera_capture_result.dart';
import '../services/inspection_camera_entry_policy_service.dart';
import '../services/inspection_flow_coordinator.dart';
import '../state/app_state.dart';

class InspectionStep2CameraUseCase {
  const InspectionStep2CameraUseCase({
    this.cameraEntryPolicy = InspectionCameraEntryPolicyService.instance,
  });

  static const InspectionStep2CameraUseCase instance =
      InspectionStep2CameraUseCase();

  final InspectionCameraEntryPolicyService cameraEntryPolicy;

  Future<OverlayCameraCaptureResult?> captureRequirement(
    BuildContext context, {
    required InspectionFlowCoordinator flowCoordinator,
    required AppState appState,
    required String tipoImovel,
    required String subtipoImovel,
    required CheckinStep2PhotoFieldConfig field,
  }) {
    return flowCoordinator.openOverlayCamera(
      context,
      request: cameraEntryPolicy.buildRequest(
        source: InspectionCameraEntrySource.step2Requirement,
        title: field.titulo,
        tipoImovel: tipoImovel,
        subtipoImovel: subtipoImovel,
        explicitSelection: FlowSelection(
          subjectContext: field.cameraMacroLocal,
          targetItem: field.cameraAmbiente,
          targetQualifier: field.cameraElementoInicial,
        ),
        step1Payload: appState.step1Payload,
        currentCaptures: const <OverlayCameraCaptureResult>[],
        inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
      ),
    );
  }

  Future<void> continuePrimaryFlow(
    BuildContext context, {
    required InspectionFlowCoordinator flowCoordinator,
    required AppState appState,
    required String tipoImovel,
    required String subtipoImovel,
    required FlowSelection initialSelection,
  }) {
    return flowCoordinator.openOverlayCamera(
      context,
      request: cameraEntryPolicy.buildRequest(
        source: InspectionCameraEntrySource.step2Continue,
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
