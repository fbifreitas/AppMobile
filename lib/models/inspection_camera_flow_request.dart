import 'inspection_capture_context.dart';
import 'flow_selection.dart';

class InspectionCameraFlowRequest {
  final String title;
  final String tipoImovel;
  final String subtipoImovel;
  final bool singleCaptureMode;
  final bool cameFromCheckinStep1;
  final FlowSelectionState selectionState;

  const InspectionCameraFlowRequest({
    required this.title,
    required this.tipoImovel,
    required this.subtipoImovel,
    required this.selectionState,
    this.singleCaptureMode = false,
    this.cameFromCheckinStep1 = false,
  });

  InspectionCaptureFlowState get captureFlowState =>
      InspectionCaptureFlowState.fromCanonical(selectionState);

  factory InspectionCameraFlowRequest.bootstrap({
    required String title,
    required String tipoImovel,
    required String subtipoImovel,
    bool singleCaptureMode = false,
    bool cameFromCheckinStep1 = false,
    InspectionCaptureContext? initialContext,
    InspectionCaptureContext? resumeContext,
  }) {
    final suggested = initialContext ?? InspectionCaptureContext.empty;
    final current =
        resumeContext?.hasAnyValue == true ? resumeContext! : suggested;
    return InspectionCameraFlowRequest(
      title: title,
      tipoImovel: tipoImovel,
      subtipoImovel: subtipoImovel,
      singleCaptureMode: singleCaptureMode,
      cameFromCheckinStep1: cameFromCheckinStep1,
      selectionState: InspectionCaptureFlowState(
        initialSuggested: suggested,
        current: current,
        resume: resumeContext?.hasAnyValue == true ? resumeContext : null,
      ).canonical,
    );
  }
}
