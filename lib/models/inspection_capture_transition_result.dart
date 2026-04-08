import 'flow_selection.dart';

class InspectionCaptureTransitionResult {
  final FlowSelectionState selectionState;
  final List<String>? ambientes;

  const InspectionCaptureTransitionResult({
    required this.selectionState,
    this.ambientes,
  });
}
