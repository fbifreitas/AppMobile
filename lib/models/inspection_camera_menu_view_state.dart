import 'inspection_capture_context.dart';
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
  final InspectionCaptureContext currentContext;

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
    required this.currentContext,
  });
}
