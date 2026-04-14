import 'inspection_review_models.dart';
import 'overlay_camera_capture_result.dart';

class InspectionCompositionEditorState {
  final List<InspectionReviewEditableCapture> items;
  final List<OverlayCameraCaptureResult> captures;
  final String? focusFilePath;

  InspectionCompositionEditorState({
    required this.items,
    required this.captures,
    required this.focusFilePath,
  });
}

class InspectionCompositionEditorResult {
  final List<InspectionReviewEditableCapture> items;
  final List<OverlayCameraCaptureResult> captures;

  const InspectionCompositionEditorResult({
    required this.items,
    required this.captures,
  });
}

class InspectionReviewEditorCatalogData {
  final List<String> macroLocais;
  final List<String> ambientes;
  final List<String> elementos;
  final List<String> materiais;
  final List<String> estados;

  const InspectionReviewEditorCatalogData({
    required this.macroLocais,
    required this.ambientes,
    required this.elementos,
    required this.materiais,
    required this.estados,
  });
}
