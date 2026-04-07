import '../config/inspection_menu_package.dart';
import '../models/flow_selection.dart';
import '../models/inspection_capture_context.dart';
import 'inspection_semantic_field_service.dart';

class InspectionCaptureContextResolver {
  const InspectionCaptureContextResolver._();

  static const InspectionCaptureContextResolver instance =
      InspectionCaptureContextResolver._();

  InspectionCaptureContext resolveFromStep1({
    required List<ConfigLevelDefinition> levels,
    required Map<String, String> selectedLevels,
  }) {
    final semanticFieldService = InspectionSemanticFieldService.instance;

    return InspectionCaptureContext(
      macroLocal: semanticFieldService.resolveSelectedValueForSemantic(
        levels: levels,
        semanticKey: InspectionSemanticFieldKeys.captureContext,
        selectedLevels: selectedLevels,
      ),
      ambiente: semanticFieldService.resolveSelectedValueForSemantic(
        levels: levels,
        semanticKey: InspectionSemanticFieldKeys.photoLocation,
        selectedLevels: selectedLevels,
      ),
      elemento: semanticFieldService.resolveSelectedValueForSemantic(
        levels: levels,
        semanticKey: InspectionSemanticFieldKeys.photoElement,
        selectedLevels: selectedLevels,
      ),
      material: semanticFieldService.resolveSelectedValueForSemantic(
        levels: levels,
        semanticKey: InspectionSemanticFieldKeys.photoMaterial,
        selectedLevels: selectedLevels,
      ),
      estado: semanticFieldService.resolveSelectedValueForSemantic(
        levels: levels,
        semanticKey: InspectionSemanticFieldKeys.photoState,
        selectedLevels: selectedLevels,
      ),
    );
  }

  FlowSelection resolveSelectionFromStep1({
    required List<ConfigLevelDefinition> levels,
    required Map<String, String> selectedLevels,
  }) {
    return resolveFromStep1(
      levels: levels,
      selectedLevels: selectedLevels,
    ).selection;
  }
}
