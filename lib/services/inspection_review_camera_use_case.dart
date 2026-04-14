import 'package:flutter/material.dart';

import '../models/flow_selection.dart';
import '../models/overlay_camera_capture_result.dart';
import '../services/inspection_camera_entry_policy_service.dart';
import '../services/inspection_flow_coordinator.dart';
import '../state/app_state.dart';

class InspectionReviewCameraUseCase {
  const InspectionReviewCameraUseCase({
    this.cameraEntryPolicy = InspectionCameraEntryPolicyService.instance,
  });

  static const InspectionReviewCameraUseCase instance =
      InspectionReviewCameraUseCase();

  final InspectionCameraEntryPolicyService cameraEntryPolicy;

  Future<OverlayCameraCaptureResult?> captureRequirement(
    BuildContext context, {
    required InspectionFlowCoordinator flowCoordinator,
    required AppState appState,
    required String tipoImovel,
    required String subtipoImovel,
    required String title,
    required FlowSelection initialSelection,
    required List<OverlayCameraCaptureResult> currentCaptures,
  }) {
    return flowCoordinator.openOverlayCamera(
      context,
      request: cameraEntryPolicy.buildRequest(
        source: InspectionCameraEntrySource.reviewRequirement,
        title: title,
        tipoImovel: tipoImovel,
        subtipoImovel: subtipoImovel,
        explicitSelection: initialSelection,
        step1Payload: appState.step1Payload,
        currentCaptures: currentCaptures,
        inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
      ),
    );
  }

  Future<OverlayCameraCaptureResult?> captureGenericPending(
    BuildContext context, {
    required InspectionFlowCoordinator flowCoordinator,
    required AppState appState,
    required String tipoImovel,
    required String subtipoImovel,
    required String title,
    FlowSelection? initialSelection,
    required List<OverlayCameraCaptureResult> currentCaptures,
  }) {
    return flowCoordinator.openOverlayCamera(
      context,
      request: cameraEntryPolicy.buildRequest(
        source: InspectionCameraEntrySource.reviewGenericPending,
        title: title,
        tipoImovel: tipoImovel,
        subtipoImovel: subtipoImovel,
        explicitSelection: initialSelection,
        step1Payload: appState.step1Payload,
        currentCaptures: currentCaptures,
        inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
      ),
    );
  }

  Future<OverlayCameraCaptureResult?> captureEditorAdd(
    BuildContext context, {
    required InspectionFlowCoordinator flowCoordinator,
    required AppState appState,
    required String tipoImovel,
    required String subtipoImovel,
    required FlowSelection seedSelection,
    required List<OverlayCameraCaptureResult> currentCaptures,
  }) {
    return flowCoordinator.openOverlayCamera(
      context,
      request: cameraEntryPolicy.buildRequest(
        source: InspectionCameraEntrySource.reviewEditorAdd,
        title: 'Nova evidência',
        tipoImovel: tipoImovel,
        subtipoImovel: subtipoImovel,
        explicitSelection: seedSelection,
        step1Payload: appState.step1Payload,
        currentCaptures: currentCaptures,
        inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
      ),
    );
  }
}
