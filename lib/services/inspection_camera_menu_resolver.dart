import '../models/inspection_camera_menu_view_state.dart';
import '../models/flow_selection.dart';
import '../models/inspection_capture_context.dart';
import 'inspection_environment_instance_service.dart';
import 'inspection_menu_service.dart';

class InspectionCameraMenuResolver {
  InspectionCameraMenuResolver({
    required InspectionMenuService menuService,
    required InspectionEnvironmentInstanceService environmentInstanceService,
  }) : _menuService = menuService,
       _environmentInstanceService = environmentInstanceService;

  final InspectionMenuService _menuService;
  final InspectionEnvironmentInstanceService _environmentInstanceService;

  Future<InspectionCameraMenuViewState> resolve({
    required String propertyType,
    required bool showMacroLocalSelector,
    required bool initialLoad,
    InspectionCaptureContext? initialSuggestedContext,
    InspectionCaptureContext? currentContext,
    FlowSelection? initialSuggestedSelection,
    FlowSelection? currentSelection,
  }) async {
    final initialSuggested = _resolveSelection(
      context: initialSuggestedContext,
      selection: initialSuggestedSelection,
    );
    final current = _resolveSelection(
      context: currentContext,
      selection: currentSelection,
    );
    final macroLocals = await _menuService.getSubjectContexts(
      propertyType: propertyType,
    );

    String? macroLocal = current.subjectContext;
    String? contextSuggestionSummary;

    if (macroLocal == null && !showMacroLocalSelector) {
      macroLocal = initialSuggested.subjectContext;
    }

    if ((macroLocal == null || macroLocal.trim().isEmpty) &&
        showMacroLocalSelector) {
      final suggestedContext = await _menuService.getSuggestedSelection(
        propertyType: propertyType,
        availableSubjectContexts: macroLocals,
      );
      if (suggestedContext?.subjectContext != null) {
        macroLocal = suggestedContext!.subjectContext!;
        contextSuggestionSummary =
            'Área da foto sugerida com base no histórico: $macroLocal';
      }
    }

    if (macroLocal != null && !macroLocals.contains(macroLocal)) {
      macroLocal = macroLocals.isNotEmpty ? macroLocals.first : null;
    }

    final fetchedAmbientes =
        macroLocal == null
            ? const <String>[]
            : await _menuService.getTargetItems(
              propertyType: propertyType,
              subjectContext: macroLocal,
            );

    final ambientes = List<String>.from(fetchedAmbientes);
    final currentAmbiente = current.targetItem;
    if (currentAmbiente != null &&
        currentAmbiente.trim().isNotEmpty &&
        !ambientes.contains(currentAmbiente)) {
      ambientes.add(currentAmbiente);
    }

    final recentAmbientes =
        macroLocal == null
            ? const <String>[]
            : await _menuService.getRecentTargetItemSuggestions(
              propertyType: propertyType,
              subjectContext: macroLocal,
              availableTargetItems: fetchedAmbientes,
            );

    String? ambiente = current.targetItem;
    if (ambiente != null && !ambientes.contains(ambiente)) {
      ambiente = null;
    }

    if ((ambiente == null || ambiente.trim().isEmpty) && macroLocal != null) {
      final suggestedContext = await _menuService.getSuggestedSelection(
        propertyType: propertyType,
        currentSelection: FlowSelection(subjectContext: macroLocal),
        availableTargetItems: fetchedAmbientes,
      );
      if (initialSuggested.targetItem == null &&
          suggestedContext?.targetItem != null) {
        ambiente = suggestedContext!.targetItem!;
        contextSuggestionSummary =
            'Contexto sugerido com base no histórico: $macroLocal • $ambiente';
      }
    }

    if (initialLoad &&
        ambiente == null &&
        ambientes.isNotEmpty &&
        !showMacroLocalSelector) {
      ambiente = ambientes.first;
    }

    final elementos =
        (macroLocal == null || ambiente == null)
            ? const <String>[]
            : await _menuService.getTargetQualifiers(
              propertyType: propertyType,
              selection: FlowSelection(
                subjectContext: macroLocal,
                targetItem: ambiente,
              ),
            );

    final recentElementos =
        (macroLocal == null || ambiente == null)
            ? const <String>[]
            : await _menuService.getRecentTargetQualifierSuggestions(
              propertyType: propertyType,
              selection: FlowSelection(
                subjectContext: macroLocal,
                targetItem: ambiente,
              ),
              availableTargetQualifiers: elementos,
            );

    String? elemento = current.targetQualifier;
    if (elemento != null && !elementos.contains(elemento)) {
      elemento = elementos.isNotEmpty ? elementos.first : null;
    }

    var prediction =
        (macroLocal == null || ambiente == null)
            ? null
            : await _menuService.getPredictionForSelection(
              propertyType: propertyType,
              selection: FlowSelection(
                subjectContext: macroLocal,
                targetItem: ambiente,
              ),
              availableTargetQualifiers: elementos,
            );

    if (elemento == null &&
        initialSuggested.targetQualifier == null &&
        prediction?.targetQualifier != null &&
        elementos.contains(prediction!.targetQualifier)) {
      elemento = prediction.targetQualifier;
    }

    final materiais =
        (macroLocal == null || ambiente == null || elemento == null)
            ? const <String>[]
            : await _menuService.getTargetQualifierMaterials(
              propertyType: propertyType,
              selection: FlowSelection(
                subjectContext: macroLocal,
                targetItem: ambiente,
                targetQualifier: elemento,
              ),
            );
    final estados =
        (macroLocal == null || ambiente == null || elemento == null)
            ? const <String>[]
            : await _menuService.getTargetConditions(
              propertyType: propertyType,
              selection: FlowSelection(
                subjectContext: macroLocal,
                targetItem: ambiente,
                targetQualifier: elemento,
              ),
            );

    prediction =
        (macroLocal == null || ambiente == null)
            ? null
            : await _menuService.getPredictionForSelection(
              propertyType: propertyType,
              selection: FlowSelection(
                subjectContext: macroLocal,
                targetItem: ambiente,
                targetQualifier: elemento,
              ),
              availableTargetQualifiers: elementos,
              availableTargetQualifierMaterials: materiais,
              availableTargetConditions: estados,
            );

    String? material = current.attributeText('inspection.material');
    if (material != null && !materiais.contains(material)) {
      material = null;
    }
    final predictedMaterial = prediction?.domainAttributes['inspection.material'];
    final predictedMaterialText =
        predictedMaterial is String
            ? predictedMaterial
            : predictedMaterial == null
            ? null
            : '$predictedMaterial';
    if (material == null &&
        predictedMaterialText != null &&
        materiais.contains(predictedMaterialText)) {
      material = predictedMaterialText;
    }

    String? estado = current.targetCondition;
    if (estado != null && !estados.contains(estado)) {
      estado = null;
    }
    if (estado == null &&
        prediction?.targetCondition != null &&
        estados.contains(prediction!.targetCondition)) {
      estado = prediction.targetCondition;
    }

    final parsed = _environmentInstanceService.parse(ambiente);
    return InspectionCameraMenuViewState(
      macroLocais: macroLocals,
      ambientes: ambientes,
      elementos: elementos,
      materiais: materiais,
      estados: estados,
      recentAmbientes: recentAmbientes,
      recentElementos: recentElementos,
      prediction: prediction,
      contextSuggestionSummary: contextSuggestionSummary,
      currentSelection: FlowSelection(
        subjectContext: macroLocal,
        targetItem: ambiente,
        targetItemBase: parsed.baseLabel,
        targetItemInstanceIndex: parsed.instanceIndex,
        targetQualifier: elemento,
        targetCondition: estado,
        domainAttributes: <String, dynamic>{
          if (material != null && material.trim().isNotEmpty)
            'inspection.material': material,
        },
      ),
    );
  }

  FlowSelection _resolveSelection({
    InspectionCaptureContext? context,
    FlowSelection? selection,
  }) {
    if (selection != null) {
      return selection;
    }
    if (context != null) {
      return context.selection;
    }
    return FlowSelection.empty;
  }
}
