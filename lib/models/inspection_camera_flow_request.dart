import 'inspection_capture_context.dart';
import 'flow_selection.dart';

class InspectionCameraFlowRequest {
  final String title;
  final String tipoImovel;
  final String subtipoImovel;
  final bool singleCaptureMode;
  final bool cameFromCheckinStep1;

  /// Canonical flow state — domain-agnostic contract.
  final FlowSelectionState selectionState;

  const InspectionCameraFlowRequest({
    required this.title,
    required this.tipoImovel,
    required this.subtipoImovel,
    required this.selectionState,
    this.singleCaptureMode = false,
    this.cameFromCheckinStep1 = false,
  });

  /// Backward-compatible accessor for callers that still use [InspectionCaptureFlowState].
  InspectionCaptureFlowState get captureFlowState =>
      InspectionCaptureFlowState.fromCanonical(selectionState);

  factory InspectionCameraFlowRequest.bootstrap({
    required String title,
    required String tipoImovel,
    required String subtipoImovel,
    bool singleCaptureMode = false,
    bool cameFromCheckinStep1 = false,
    FlowSelection? initialSelection,
    FlowSelection? resumeSelection,
    // Backward-compat: prefer initialSelection / resumeSelection in new code.
    InspectionCaptureContext? initialContext,
    InspectionCaptureContext? resumeContext,
  }) {
    final suggested =
        initialSelection ??
        initialContext?.selection ??
        FlowSelection.empty;
    final resume =
        resumeSelection ??
        (resumeContext?.hasAnyValue == true ? resumeContext!.selection : null);
    final current =
        (resume != null && resume.hasAnyValue) ? resume : suggested;
    return InspectionCameraFlowRequest(
      title: title,
      tipoImovel: tipoImovel,
      subtipoImovel: subtipoImovel,
      singleCaptureMode: singleCaptureMode,
      cameFromCheckinStep1: cameFromCheckinStep1,
      selectionState: FlowSelectionState(
        initialSuggestedSelection: suggested,
        currentSelection: current,
        resumeSelection: (resume != null && resume.hasAnyValue) ? resume : null,
      ),
    );
  }
}
