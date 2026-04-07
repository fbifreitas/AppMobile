import '../models/flow_selection.dart';
import '../models/inspection_capture_context.dart';
import '../models/overlay_camera_capture_result.dart';
import 'contextual_item_instance_service.dart';

class InspectionDomainAdapter {
  const InspectionDomainAdapter({
    ContextualItemInstanceService instanceService =
        ContextualItemInstanceService.instance,
  }) : _instanceService = instanceService;

  static const InspectionDomainAdapter instance = InspectionDomainAdapter();
  static const String materialAttributeKey = 'inspection.material';

  static const List<String> _environmentOptions = <String>[
    'Fachada',
    'Logradouro',
    'Acesso ao imóvel',
    'Entorno',
    'Sala de Estar',
    'Sala',
    'Dormitório',
    'Cozinha',
    'Banheiro',
    'Área de serviço',
    'Áreas Comuns',
    'Garagem',
    'Outro ambiente',
  ];

  static const List<String> _elementOptions = <String>[
    'Visão geral',
    'Número',
    'Porta',
    'Portão',
    'Janela',
    'Piso',
    'Parede',
    'Teto',
    'Outro',
  ];

  static const List<String> _materialOptions = <String>[
    'Alvenaria',
    'Metal',
    'Madeira',
    'Vidro',
    'Cerâmica',
    'Concreto',
    'Outro',
  ];

  static const List<String> _stateOptions = <String>[
    'Bom',
    'Regular',
    'Ruim',
    'Necessita reparo',
    'Não se aplica',
  ];

  final ContextualItemInstanceService _instanceService;

  List<String> environmentOptions() => _environmentOptions;
  List<String> elementOptions() => _elementOptions;
  List<String> materialOptions() => _materialOptions;
  List<String> stateOptions() => _stateOptions;

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
