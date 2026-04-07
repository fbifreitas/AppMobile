import 'flow_selection.dart';
import 'inspection_capture_context.dart';

class InspectionCaptureTransitionResult {
  final FlowSelectionState selectionState;
  final List<String>? ambientes;

  const InspectionCaptureTransitionResult({
    required this.selectionState,
    this.ambientes,
  });

  InspectionCaptureFlowState get flowState =>
      InspectionCaptureFlowState.fromCanonical(selectionState);

  /// Canonical alias for [ambientes] — prefer in new code.
  List<String>? get availableTargetItems => ambientes;
}
