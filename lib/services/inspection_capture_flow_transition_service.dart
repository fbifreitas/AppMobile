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
    required InspectionCaptureFlowState flowState,
    required String value,
  }) async {
    await _menuService.registerUsage(
      scope: 'camera.${propertyType.toLowerCase()}.macro',
      value: value,
    );

    return InspectionCaptureTransitionResult(
      flowState: flowState.copyWith(
        current: flowState.current.copyWith(
          macroLocal: value,
          clearAmbiente: true,
          clearAmbienteBase: true,
          clearAmbienteInstanceIndex: true,
          clearElemento: true,
          clearMaterial: true,
          clearEstado: true,
        ),
      ),
    );
  }

  Future<InspectionCaptureTransitionResult> selectAmbiente({
    required String propertyType,
    required InspectionCaptureFlowState flowState,
    required String? macroLocal,
    required String value,
  }) async {
    await _menuService.registerUsage(
      scope: 'camera.${propertyType.toLowerCase()}.$macroLocal.ambiente',
      value: value,
    );

    final parsed = _environmentInstanceService.parse(value);
    return InspectionCaptureTransitionResult(
      flowState: flowState.copyWith(
        current: flowState.current.copyWith(
          ambiente: value,
          ambienteBase: parsed.baseLabel,
          ambienteInstanceIndex: parsed.instanceIndex,
          clearElemento: true,
          clearMaterial: true,
          clearEstado: true,
        ),
      ),
    );
  }

  Future<InspectionCaptureTransitionResult?> duplicateAmbiente({
    required String propertyType,
    required InspectionCaptureFlowState flowState,
    required String? macroLocal,
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
    final updatedFlowState = flowState.copyWith(
      current: flowState.current.copyWith(
        ambiente: nextLabel,
        ambienteBase: parsed.baseLabel,
        ambienteInstanceIndex: parsed.instanceIndex,
        clearElemento: true,
        clearMaterial: true,
        clearEstado: true,
      ),
    );

    if (!useTestMenuData) {
      await _menuService.registerUsage(
        scope: 'camera.${propertyType.toLowerCase()}.$macroLocal.ambiente',
        value: nextLabel,
      );
    }

    return InspectionCaptureTransitionResult(
      flowState: updatedFlowState,
      ambientes: nextAmbientes,
    );
  }

  Future<InspectionCaptureTransitionResult> selectElemento({
    required String propertyType,
    required InspectionCaptureFlowState flowState,
    required String? macroLocal,
    required String? ambiente,
    required String value,
  }) async {
    await _menuService.registerUsage(
      scope:
          'camera.${propertyType.toLowerCase()}.$macroLocal.$ambiente.elemento',
      value: value,
    );

    return InspectionCaptureTransitionResult(
      flowState: flowState.copyWith(
        current: flowState.current.copyWith(
          elemento: value,
          clearMaterial: true,
          clearEstado: true,
        ),
      ),
    );
  }

  InspectionCaptureTransitionResult selectMaterial({
    required InspectionCaptureFlowState flowState,
    required String value,
  }) {
    return InspectionCaptureTransitionResult(
      flowState: flowState.copyWith(
        current: flowState.current.copyWith(
          material: value,
          clearEstado: true,
        ),
      ),
    );
  }

  InspectionCaptureTransitionResult selectEstado({
    required InspectionCaptureFlowState flowState,
    required String value,
  }) {
    return InspectionCaptureTransitionResult(
      flowState: flowState.copyWith(
        current: flowState.current.copyWith(estado: value),
      ),
    );
  }
}
