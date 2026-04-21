import '../models/flow_selection.dart';
import '../models/inspection_camera_flow_request.dart';
import '../models/overlay_camera_capture_result.dart';
import 'inspection_capture_recovery_adapter.dart';

enum InspectionCameraEntrySource {
  step1,
  step2Requirement,
  step2Continue,
  reviewRequirement,
  reviewGenericPending,
  reviewEditorAdd,
}

class InspectionCameraEntryPolicyService {
  const InspectionCameraEntryPolicyService({
    this.recoveryAdapter = InspectionCaptureRecoveryAdapter.instance,
  });

  static const InspectionCameraEntryPolicyService instance =
      InspectionCameraEntryPolicyService();

  final InspectionCaptureRecoveryAdapter recoveryAdapter;

  InspectionCameraFlowRequest buildRequest({
    required InspectionCameraEntrySource source,
    required String title,
    required String tipoImovel,
    required String subtipoImovel,
    FlowSelection? explicitSelection,
    required Map<String, dynamic> step1Payload,
    required List<OverlayCameraCaptureResult> currentCaptures,
    required Map<String, dynamic> inspectionRecoveryPayload,
  }) {
    final freeCaptureMode = step1Payload['freeCaptureModeEnabled'] == true;
    final explicitSelectionHasValue = explicitSelection?.hasAnyValue == true;
    final initialSelection =
        freeCaptureMode
            ? FlowSelection.empty
            : explicitSelectionHasValue
            ? explicitSelection!
            : resolveFallbackSelection(
              step1Payload: step1Payload,
              inspectionRecoveryPayload: inspectionRecoveryPayload,
            );
    final resumeSelection =
        !freeCaptureMode && _shouldUseResumeSelection(source)
            ? recoveryAdapter.resolveResumeSelection(
              currentCaptures: currentCaptures,
              inspectionRecoveryPayload: inspectionRecoveryPayload,
            )
            : null;

    return InspectionCameraFlowRequest.bootstrap(
      title: title,
      tipoImovel: tipoImovel,
      subtipoImovel: subtipoImovel,
      singleCaptureMode: _singleCaptureMode(source),
      cameFromCheckinStep1: _cameFromCheckinStep1(source),
      freeCaptureMode: freeCaptureMode,
      initialSelection: initialSelection,
      preferInitialSelection:
          freeCaptureMode
              ? false
              : source == InspectionCameraEntrySource.step1
              ? explicitSelectionHasValue
              : (initialSelection.hasAnyValue && resumeSelection == null),
      resumeSelection: resumeSelection,
    );
  }

  FlowSelection resolveFallbackSelection({
    required Map<String, dynamic> step1Payload,
    required Map<String, dynamic> inspectionRecoveryPayload,
  }) {
    final directContext = step1Payload['porOndeComecar'];
    if (directContext is String && directContext.trim().isNotEmpty) {
      return FlowSelection(subjectContext: directContext.trim());
    }

    final rawStep1 = inspectionRecoveryPayload['step1'];
    if (rawStep1 is Map) {
      final restoredContext = rawStep1['porOndeComecar'];
      if (restoredContext is String && restoredContext.trim().isNotEmpty) {
        return FlowSelection(subjectContext: restoredContext.trim());
      }

      final restoredLevels = rawStep1['niveis'];
      if (restoredLevels is Map) {
        for (final entry in restoredLevels.entries) {
          final key = '${entry.key}'.trim().toLowerCase();
          final value = '${entry.value}'.trim();
          if (value.isEmpty) continue;
          if (key == 'contexto' || key == 'porondecomecar') {
            return FlowSelection(subjectContext: value);
          }
        }
      }
    }

    return FlowSelection.empty;
  }

  bool _singleCaptureMode(InspectionCameraEntrySource source) {
    return switch (source) {
      InspectionCameraEntrySource.step1 => false,
      InspectionCameraEntrySource.step2Requirement => true,
      InspectionCameraEntrySource.step2Continue => false,
      InspectionCameraEntrySource.reviewRequirement => true,
      InspectionCameraEntrySource.reviewGenericPending => true,
      InspectionCameraEntrySource.reviewEditorAdd => true,
    };
  }

  bool _cameFromCheckinStep1(InspectionCameraEntrySource source) {
    return switch (source) {
      InspectionCameraEntrySource.step1 => true,
      InspectionCameraEntrySource.step2Requirement => false,
      InspectionCameraEntrySource.step2Continue => true,
      InspectionCameraEntrySource.reviewRequirement => false,
      InspectionCameraEntrySource.reviewGenericPending => false,
      InspectionCameraEntrySource.reviewEditorAdd => false,
    };
  }

  bool _shouldUseResumeSelection(InspectionCameraEntrySource source) {
    return switch (source) {
      InspectionCameraEntrySource.step1 => true,
      InspectionCameraEntrySource.step2Requirement => false,
      InspectionCameraEntrySource.step2Continue => true,
      InspectionCameraEntrySource.reviewRequirement => false,
      InspectionCameraEntrySource.reviewGenericPending => false,
      InspectionCameraEntrySource.reviewEditorAdd => false,
    };
  }
}
