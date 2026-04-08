import '../models/flow_selection.dart';
import '../models/inspection_capture_context.dart';
import '../models/overlay_camera_capture_result.dart';
import 'contextual_item_instance_service.dart';
import 'inspection_taxonomy_service.dart';

class InspectionDomainAdapter {
  const InspectionDomainAdapter({
    ContextualItemInstanceService instanceService =
        ContextualItemInstanceService.instance,
    InspectionTaxonomyService taxonomyService =
        InspectionTaxonomyService.instance,
  }) : _instanceService = instanceService,
       _taxonomyService = taxonomyService;

  static const InspectionDomainAdapter instance = InspectionDomainAdapter();
  static const String materialAttributeKey = 'inspection.material';

  final ContextualItemInstanceService _instanceService;
  final InspectionTaxonomyService _taxonomyService;

  List<String> environmentOptions() => _taxonomyService.environmentOptions();
  List<String> elementOptions() => _taxonomyService.elementOptions();
  List<String> materialOptions() => _taxonomyService.materialOptions();
  List<String> stateOptions() => _taxonomyService.stateOptions();

  String? inspectionMaterialOf(FlowSelection selection) =>
      selection.attributeText(materialAttributeKey);

  InspectionCaptureContext toInspectionContext(FlowSelection selection) {
    return InspectionCaptureContext.canonical(
      subjectContext: selection.subjectContext,
      targetItem: selection.targetItem,
      targetItemBase: selection.targetItemBase,
      targetItemInstanceIndex: selection.targetItemInstanceIndex,
      targetQualifier: selection.targetQualifier,
      targetCondition: selection.targetCondition,
      domainAttributes: selection.domainAttributes,
    );
  }

  FlowSelection fromCapture(OverlayCameraCaptureResult capture) {
    return capture.selection;
  }

  String? duplicateActionLabelFor(String? selectedTargetItem) {
    final parsed = _instanceService.parse(selectedTargetItem);
    final baseLabel = parsed.baseLabel.trim();
    if (baseLabel.isEmpty) {
      return null;
    }
    final prefix = baseLabel.toLowerCase().endsWith('a') ? 'Nova' : 'Novo';
    return '$prefix $baseLabel';
  }
}
