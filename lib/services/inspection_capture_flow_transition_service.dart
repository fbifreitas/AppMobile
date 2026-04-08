import '../models/flow_selection.dart';
import '../models/inspection_capture_transition_result.dart';
import 'inspection_context_actions_service.dart';
import 'inspection_environment_instance_service.dart';
import 'inspection_menu_service.dart';

class InspectionCaptureFlowTransitionService {
  InspectionCaptureFlowTransitionService({
    required InspectionMenuService menuService,
    required InspectionEnvironmentInstanceService environmentInstanceService,
    required InspectionContextActionsService contextActionsService,
  }) : _menuService = menuService,
       _environmentInstanceService = environmentInstanceService,
       _contextActionsService = contextActionsService;

  final InspectionMenuService _menuService;
  final InspectionEnvironmentInstanceService _environmentInstanceService;
  final InspectionContextActionsService _contextActionsService;

  Future<InspectionCaptureTransitionResult> selectMacroLocal({
    required String propertyType,
    required FlowSelectionState selectionState,
    required String value,
  }) async {
    await _menuService.registerUsage(
      scope: 'camera.${propertyType.toLowerCase()}.macro',
      value: value,
    );

    return InspectionCaptureTransitionResult(
      selectionState: selectionState.copyWith(
        currentSelection: selectionState.currentSelection.copyWith(
          subjectContext: value,
          clearTargetItem: true,
          clearTargetItemBase: true,
          clearTargetItemInstanceIndex: true,
          clearTargetQualifier: true,
          clearTargetCondition: true,
          clearDomainAttributes: true,
        ),
      ),
    );
  }

  Future<InspectionCaptureTransitionResult> selectAmbiente({
    required String propertyType,
    required FlowSelectionState selectionState,
    required String value,
  }) async {
    final macroLocal = selectionState.currentSelection.subjectContext;
    await _menuService.registerUsage(
      scope: 'camera.${propertyType.toLowerCase()}.$macroLocal.ambiente',
      value: value,
    );

    final parsed = _environmentInstanceService.parse(value);
    return InspectionCaptureTransitionResult(
      selectionState: selectionState.copyWith(
        currentSelection: selectionState.currentSelection.copyWith(
          targetItem: value,
          targetItemBase: parsed.baseLabel,
          targetItemInstanceIndex: parsed.instanceIndex,
          clearTargetQualifier: true,
          clearTargetCondition: true,
          clearDomainAttributes: true,
        ),
      ),
    );
  }

  Future<InspectionCaptureTransitionResult?> duplicateAmbiente({
    required String propertyType,
    required FlowSelectionState selectionState,
    required String? selectedAmbiente,
    required List<String> existingAmbientes,
    required bool useTestMenuData,
  }) async {
    if (selectedAmbiente == null || selectedAmbiente.trim().isEmpty) {
      return null;
    }

    final nextLabel = _contextActionsService.nextDuplicatedAmbienteLabel(
      selectedAmbiente: selectedAmbiente,
      existingLabels: existingAmbientes,
    );
    if (nextLabel.trim().isEmpty) {
      return null;
    }

    final nextAmbientes = List<String>.from(existingAmbientes);
    if (!nextAmbientes.contains(nextLabel)) {
      nextAmbientes.add(nextLabel);
    }

    final parsed = _environmentInstanceService.parse(nextLabel);
    final updatedSelectionState = selectionState.copyWith(
      currentSelection: selectionState.currentSelection.copyWith(
        targetItem: nextLabel,
        targetItemBase: parsed.baseLabel,
        targetItemInstanceIndex: parsed.instanceIndex,
        clearTargetQualifier: true,
        clearTargetCondition: true,
        clearDomainAttributes: true,
      ),
    );

    if (!useTestMenuData) {
      final macroLocal = selectionState.currentSelection.subjectContext;
      await _menuService.registerUsage(
        scope: 'camera.${propertyType.toLowerCase()}.$macroLocal.ambiente',
        value: nextLabel,
      );
    }

    return InspectionCaptureTransitionResult(
      selectionState: updatedSelectionState,
      ambientes: nextAmbientes,
    );
  }

  Future<InspectionCaptureTransitionResult> selectElemento({
    required String propertyType,
    required FlowSelectionState selectionState,
    required String value,
  }) async {
    final macroLocal = selectionState.currentSelection.subjectContext;
    final ambiente = selectionState.currentSelection.targetItem;
    await _menuService.registerUsage(
      scope:
          'camera.${propertyType.toLowerCase()}.$macroLocal.$ambiente.elemento',
      value: value,
    );

    return InspectionCaptureTransitionResult(
      selectionState: selectionState.copyWith(
        currentSelection: selectionState.currentSelection.copyWith(
          targetQualifier: value,
          clearTargetCondition: true,
          clearDomainAttributes: true,
        ),
      ),
    );
  }

  InspectionCaptureTransitionResult selectMaterial({
    required FlowSelectionState selectionState,
    required String value,
  }) {
    final domainAttributes = <String, dynamic>{
      ...selectionState.currentSelection.domainAttributes,
      'inspection.material': value,
    };
    return InspectionCaptureTransitionResult(
      selectionState: selectionState.copyWith(
        currentSelection: selectionState.currentSelection.copyWith(
          domainAttributes: domainAttributes,
          clearTargetCondition: true,
        ),
      ),
    );
  }

  InspectionCaptureTransitionResult selectEstado({
    required FlowSelectionState selectionState,
    required String value,
  }) {
    return InspectionCaptureTransitionResult(
      selectionState: selectionState.copyWith(
        currentSelection: selectionState.currentSelection.copyWith(
          targetCondition: value,
        ),
      ),
    );
  }
}
