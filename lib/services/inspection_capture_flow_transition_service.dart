import '../models/flow_selection.dart';
import '../models/inspection_capture_context.dart';
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
    InspectionCaptureFlowState? flowState,
    FlowSelectionState? selectionState,
    required String value,
  }) async {
    final state = _resolveSelectionState(
      flowState: flowState,
      selectionState: selectionState,
    );
    await _menuService.registerUsage(
      scope: 'camera.${propertyType.toLowerCase()}.macro',
      value: value,
    );

    return InspectionCaptureTransitionResult(
      selectionState: state.copyWith(
        currentSelection: state.currentSelection.copyWith(
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
    InspectionCaptureFlowState? flowState,
    FlowSelectionState? selectionState,
    required String? macroLocal,
    required String value,
  }) async {
    final state = _resolveSelectionState(
      flowState: flowState,
      selectionState: selectionState,
    );
    await _menuService.registerUsage(
      scope: 'camera.${propertyType.toLowerCase()}.$macroLocal.ambiente',
      value: value,
    );

    final parsed = _environmentInstanceService.parse(value);
    return InspectionCaptureTransitionResult(
      selectionState: state.copyWith(
        currentSelection: state.currentSelection.copyWith(
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
    InspectionCaptureFlowState? flowState,
    FlowSelectionState? selectionState,
    required String? macroLocal,
    required String? selectedAmbiente,
    required List<String> existingAmbientes,
    required bool useTestMenuData,
  }) async {
    final state = _resolveSelectionState(
      flowState: flowState,
      selectionState: selectionState,
    );
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
    final updatedSelectionState = state.copyWith(
      currentSelection: state.currentSelection.copyWith(
        targetItem: nextLabel,
        targetItemBase: parsed.baseLabel,
        targetItemInstanceIndex: parsed.instanceIndex,
        clearTargetQualifier: true,
        clearTargetCondition: true,
        clearDomainAttributes: true,
      ),
    );

    if (!useTestMenuData) {
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
    InspectionCaptureFlowState? flowState,
    FlowSelectionState? selectionState,
    required String? macroLocal,
    required String? ambiente,
    required String value,
  }) async {
    final state = _resolveSelectionState(
      flowState: flowState,
      selectionState: selectionState,
    );
    await _menuService.registerUsage(
      scope:
          'camera.${propertyType.toLowerCase()}.$macroLocal.$ambiente.elemento',
      value: value,
    );

    return InspectionCaptureTransitionResult(
      selectionState: state.copyWith(
        currentSelection: state.currentSelection.copyWith(
          targetQualifier: value,
          clearTargetCondition: true,
          clearDomainAttributes: true,
        ),
      ),
    );
  }

  InspectionCaptureTransitionResult selectMaterial({
    InspectionCaptureFlowState? flowState,
    FlowSelectionState? selectionState,
    required String value,
  }) {
    final state = _resolveSelectionState(
      flowState: flowState,
      selectionState: selectionState,
    );
    final domainAttributes = <String, dynamic>{
      ...state.currentSelection.domainAttributes,
      'inspection.material': value,
    };
    return InspectionCaptureTransitionResult(
      selectionState: state.copyWith(
        currentSelection: state.currentSelection.copyWith(
          domainAttributes: domainAttributes,
          clearTargetCondition: true,
        ),
      ),
    );
  }

  InspectionCaptureTransitionResult selectEstado({
    InspectionCaptureFlowState? flowState,
    FlowSelectionState? selectionState,
    required String value,
  }) {
    final state = _resolveSelectionState(
      flowState: flowState,
      selectionState: selectionState,
    );
    return InspectionCaptureTransitionResult(
      selectionState: state.copyWith(
        currentSelection: state.currentSelection.copyWith(
          targetCondition: value,
        ),
      ),
    );
  }

  FlowSelectionState _resolveSelectionState({
    InspectionCaptureFlowState? flowState,
    FlowSelectionState? selectionState,
  }) {
    if (selectionState != null) {
      return selectionState;
    }
    if (flowState != null) {
      return flowState.canonical;
    }
    throw ArgumentError(
      'Either flowState or selectionState must be provided.',
    );
  }
}
