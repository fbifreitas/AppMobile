import 'flow_selection.dart';
import 'inspection_menu_intelligence_models.dart';

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

  /// Canonical resolved selection — single source of truth for current state.
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

  List<String> get captureContexts => macroLocais;
  List<String> get targetItems => ambientes;
  List<String> get targetQualifiers => elementos;
  List<String> get materialAttributes => materiais;
  List<String> get conditionStates => estados;
  List<String> get recentTargetItems => recentAmbientes;
  List<String> get recentTargetQualifiers => recentElementos;
}
