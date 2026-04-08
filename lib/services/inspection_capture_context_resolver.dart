import '../config/inspection_menu_package.dart';
import '../models/flow_selection.dart';
import 'inspection_semantic_field_service.dart';

class InspectionCaptureContextResolver {
  const InspectionCaptureContextResolver._();

  static const InspectionCaptureContextResolver instance =
      InspectionCaptureContextResolver._();

  /// Resolves canonical [FlowSelection] from the step-1 checkin level selections.
  FlowSelection resolveFromStep1({
    required List<ConfigLevelDefinition> levels,
    required Map<String, String> selectedLevels,
  }) {
    final semanticFieldService = InspectionSemanticFieldService.instance;

    final material = semanticFieldService.resolveSelectedValueForSemantic(
      levels: levels,
      semanticKey: InspectionSemanticFieldKeys.photoMaterial,
      selectedLevels: selectedLevels,
    );

    return FlowSelection(
      subjectContext: semanticFieldService.resolveSelectedValueForSemantic(
        levels: levels,
        semanticKey: InspectionSemanticFieldKeys.captureContext,
        selectedLevels: selectedLevels,
      ),
      targetItem: semanticFieldService.resolveSelectedValueForSemantic(
        levels: levels,
        semanticKey: InspectionSemanticFieldKeys.photoLocation,
        selectedLevels: selectedLevels,
      ),
      targetQualifier: semanticFieldService.resolveSelectedValueForSemantic(
        levels: levels,
        semanticKey: InspectionSemanticFieldKeys.photoElement,
        selectedLevels: selectedLevels,
      ),
      targetCondition: semanticFieldService.resolveSelectedValueForSemantic(
        levels: levels,
        semanticKey: InspectionSemanticFieldKeys.photoState,
        selectedLevels: selectedLevels,
      ),
      domainAttributes: <String, dynamic>{
        if (material != null && material.trim().isNotEmpty)
          'inspection.material': material,
      },
    );
  }
}
