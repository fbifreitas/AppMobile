import 'inspection_capture_context.dart';

class InspectionCaptureTransitionResult {
  final InspectionCaptureFlowState flowState;
  final List<String>? ambientes;

  const InspectionCaptureTransitionResult({
    required this.flowState,
    this.ambientes,
  });
}
