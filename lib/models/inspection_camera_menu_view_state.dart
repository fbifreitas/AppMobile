import 'inspection_capture_context.dart';
import 'inspection_menu_intelligence_models.dart';
import 'flow_selection.dart';

class InspectionCameraMenuViewState {
  final List<String> macroLocais;
  final List<String> ambientes;
  final List<String> elementos;
  final List<String> materiais;
  final List<String> estados;
  final List<String> recentAmbientes;
  final List<String> recentElementos;
  final PredictedSelection? prediction;
  final String? contextSuggestionSummary;
  final FlowSelection currentSelection;

  const InspectionCameraMenuViewState({
    required this.macroLocais,
    required this.ambientes,
    required this.elementos,
    required this.materiais,
    required this.estados,
    required this.recentAmbientes,
    required this.recentElementos,
    required this.prediction,
    required this.contextSuggestionSummary,
    required this.currentSelection,
  });

  InspectionCaptureContext get currentContext =>
      InspectionCaptureContext.fromMap(
        currentSelection.toMap(includeCanonical: true, includeLegacy: true),
      );

  // Canonical aliases — prefer these in new code
  List<String> get subjectContextOptions => macroLocais;
  List<String> get targetItemOptions => ambientes;
  List<String> get targetQualifierOptions => elementos;
  List<String> get targetQualifierAttributeOptions => materiais;
  List<String> get targetConditionOptions => estados;
  List<String> get recentTargetItems => recentAmbientes;
  List<String> get recentTargetQualifiers => recentElementos;
}
