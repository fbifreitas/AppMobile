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

  factory InspectionCameraFlowRequest.bootstrap({
    required String title,
    required String tipoImovel,
    required String subtipoImovel,
    bool singleCaptureMode = false,
    bool cameFromCheckinStep1 = false,
    FlowSelection? initialSelection,
    FlowSelection? resumeSelection,
  }) {
    final suggested = initialSelection ?? FlowSelection.empty;
    final resume = resumeSelection;
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
