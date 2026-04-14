import '../models/flow_selection.dart';
import '../models/inspection_camera_menu_view_state.dart';
import 'contextual_item_instance_service.dart';
import 'inspection_menu_service.dart';

class InspectionCameraMenuResolver {
  InspectionCameraMenuResolver({
    required InspectionMenuService menuService,
    ContextualItemInstanceService instanceService =
        ContextualItemInstanceService.instance,
  }) : _menuService = menuService,
       _instanceService = instanceService;

  final InspectionMenuService _menuService;
  final ContextualItemInstanceService _instanceService;

  Future<InspectionCameraMenuViewState> resolve({
    required String propertyType,
    String? subtipo,
    required bool showMacroLocalSelector,
    required bool initialLoad,
    required FlowSelection initialSuggestedSelection,
    required FlowSelection currentSelection,
  }) async {
    final macroLocals = await _menuService.getMacroLocals(
      propertyType: propertyType,
      subtipo: subtipo,
    );

    String? subjectContext = currentSelection.subjectContext;
    String? contextSuggestionSummary;

    if (subjectContext == null && !showMacroLocalSelector) {
      subjectContext = initialSuggestedSelection.subjectContext;
    }

    if ((subjectContext == null || subjectContext.trim().isEmpty) &&
        showMacroLocalSelector) {
      final suggestedContext = await _menuService.getSuggestedContext(
        propertyType: propertyType,
        availableMacroLocals: macroLocals,
      );
      if (suggestedContext?.macroLocal != null) {
        subjectContext = suggestedContext!.macroLocal!;
        contextSuggestionSummary =
            'Área da foto sugerida com base no histórico: $subjectContext';
      }
    }

    if (subjectContext != null && !macroLocals.contains(subjectContext)) {
      subjectContext = macroLocals.isNotEmpty ? macroLocals.first : null;
    }

    final fetchedAmbientes =
        subjectContext == null
            ? const <String>[]
            : await _menuService.getAmbientes(
              propertyType: propertyType,
              subtipo: subtipo,
              macroLocal: subjectContext,
            );

    final ambientes = List<String>.from(fetchedAmbientes);
    final currentTargetItem = currentSelection.targetItem;
    if (currentTargetItem != null &&
        currentTargetItem.trim().isNotEmpty &&
        !ambientes.contains(currentTargetItem)) {
      ambientes.add(currentTargetItem);
    }

    final recentAmbientes =
        subjectContext == null
            ? const <String>[]
            : await _menuService.getRecentAmbienteSuggestions(
              propertyType: propertyType,
              macroLocal: subjectContext,
              availableAmbientes: fetchedAmbientes,
            );

    String? targetItem = currentSelection.targetItem;
    if (targetItem != null && !ambientes.contains(targetItem)) {
      targetItem = null;
    }

    final hasExplicitInitialContextOnly =
        initialSuggestedSelection.subjectContext != null &&
        initialSuggestedSelection.subjectContext!.trim().isNotEmpty &&
        (initialSuggestedSelection.targetItem == null ||
            initialSuggestedSelection.targetItem!.trim().isEmpty);

    if ((targetItem == null || targetItem.trim().isEmpty) &&
        subjectContext != null &&
        !hasExplicitInitialContextOnly) {
      final suggestedContext = await _menuService.getSuggestedContext(
        propertyType: propertyType,
        macroLocal: subjectContext,
        availableAmbientes: fetchedAmbientes,
      );
      if (initialSuggestedSelection.targetItem == null &&
          suggestedContext?.ambiente != null) {
        targetItem = suggestedContext!.ambiente!;
        contextSuggestionSummary =
            'Contexto sugerido com base no histórico: $subjectContext • $targetItem';
      }
    }

    if (initialLoad &&
        targetItem == null &&
        ambientes.isNotEmpty &&
        !showMacroLocalSelector) {
      targetItem = ambientes.first;
    }

    final elementos =
        (subjectContext == null || targetItem == null)
            ? const <String>[]
            : await _menuService.getElementos(
              propertyType: propertyType,
              subtipo: subtipo,
              macroLocal: subjectContext,
              ambiente: targetItem,
            );

    final recentElementos =
        (subjectContext == null || targetItem == null)
            ? const <String>[]
            : await _menuService.getRecentElementSuggestions(
              propertyType: propertyType,
              macroLocal: subjectContext,
              ambiente: targetItem,
              availableElementos: elementos,
            );

    String? targetQualifier = currentSelection.targetQualifier;
    if (targetQualifier != null && !elementos.contains(targetQualifier)) {
      targetQualifier = elementos.isNotEmpty ? elementos.first : null;
    }

    var prediction =
        (subjectContext == null || targetItem == null)
            ? null
            : await _menuService.getPrediction(
              propertyType: propertyType,
              macroLocal: subjectContext,
              ambiente: targetItem,
              availableElementos: elementos,
            );

    if (targetQualifier == null &&
        initialSuggestedSelection.targetQualifier == null &&
        prediction?.elemento != null &&
        elementos.contains(prediction!.elemento)) {
      targetQualifier = prediction.elemento;
    }

    final materiais =
        (subjectContext == null || targetItem == null || targetQualifier == null)
            ? const <String>[]
            : await _menuService.getMateriais(
              propertyType: propertyType,
              subtipo: subtipo,
              macroLocal: subjectContext,
              ambiente: targetItem,
              elemento: targetQualifier,
            );

    final estados =
        (subjectContext == null || targetItem == null || targetQualifier == null)
            ? const <String>[]
            : await _menuService.getEstados(
              propertyType: propertyType,
              subtipo: subtipo,
              macroLocal: subjectContext,
              ambiente: targetItem,
              elemento: targetQualifier,
            );

    prediction =
        (subjectContext == null || targetItem == null)
            ? null
            : await _menuService.getPrediction(
              propertyType: propertyType,
              macroLocal: subjectContext,
              ambiente: targetItem,
              availableElementos: elementos,
              availableMateriais: materiais,
              availableEstados: estados,
            );

    // material lives in domainAttributes — read and reconcile
    final currentMaterial = currentSelection.attributeText('inspection.material');
    String? resolvedMaterial = currentMaterial;
    if (resolvedMaterial != null && !materiais.contains(resolvedMaterial)) {
      resolvedMaterial = null;
    }
    if (resolvedMaterial == null &&
        prediction?.material != null &&
        materiais.contains(prediction!.material)) {
      resolvedMaterial = prediction.material;
    }

    String? targetCondition = currentSelection.targetCondition;
    if (targetCondition != null && !estados.contains(targetCondition)) {
      targetCondition = null;
    }
    if (targetCondition == null &&
        prediction?.estado != null &&
        estados.contains(prediction!.estado)) {
      targetCondition = prediction.estado;
    }

    final parsed = _instanceService.parse(targetItem);

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
        subjectContext: subjectContext,
        targetItem: targetItem,
        targetItemBase: parsed.baseLabel.isNotEmpty ? parsed.baseLabel : null,
        targetItemInstanceIndex:
            parsed.instanceIndex > 0 ? parsed.instanceIndex : null,
        targetQualifier: targetQualifier,
        targetCondition: targetCondition,
        domainAttributes: Map<String, dynamic>.unmodifiable(
          resolvedMaterial != null
              ? {
                ...currentSelection.domainAttributes,
                'inspection.material': resolvedMaterial,
              }
              : Map.fromEntries(
                currentSelection.domainAttributes.entries
                    .where((e) => e.key != 'inspection.material'),
              ),
        ),
      ),
    );
  }

  Future<InspectionCameraMenuViewState> resolveCanonical({
    required String assetType,
    String? assetSubtype,
    required bool showCaptureContextSelector,
    required bool initialLoad,
    required FlowSelection initialSuggestedSelection,
    required FlowSelection currentSelection,
  }) {
    return resolve(
      propertyType: assetType,
      subtipo: assetSubtype,
      showMacroLocalSelector: showCaptureContextSelector,
      initialLoad: initialLoad,
      initialSuggestedSelection: initialSuggestedSelection,
      currentSelection: currentSelection,
    );
  }
}
