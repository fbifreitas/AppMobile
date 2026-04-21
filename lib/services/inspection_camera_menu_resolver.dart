import '../models/flow_selection.dart';
import '../models/inspection_camera_menu_view_state.dart';
import '../models/smart_execution_plan.dart';
import 'contextual_item_instance_service.dart';
import 'inspection_menu_service.dart';
import 'smart_execution_plan_menu_overlay_service.dart';

class InspectionCameraMenuResolver {
  InspectionCameraMenuResolver({
    required InspectionMenuService menuService,
    SmartExecutionPlanMenuOverlayService executionPlanMenuOverlayService =
        SmartExecutionPlanMenuOverlayService.instance,
    ContextualItemInstanceService instanceService =
        ContextualItemInstanceService.instance,
  }) : _menuService = menuService,
       _executionPlanMenuOverlayService = executionPlanMenuOverlayService,
       _instanceService = instanceService;

  final InspectionMenuService _menuService;
  final SmartExecutionPlanMenuOverlayService _executionPlanMenuOverlayService;
  final ContextualItemInstanceService _instanceService;

  Future<InspectionCameraMenuViewState> resolve({
    required String propertyType,
    String? subtipo,
    SmartExecutionPlan? executionPlan,
    List<String> currentKnownAmbientes = const <String>[],
    required bool showMacroLocalSelector,
    required bool initialLoad,
    required FlowSelection initialSuggestedSelection,
    required FlowSelection currentSelection,
  }) async {
    final macroLocals = _executionPlanMenuOverlayService.macroLocals(
      executionPlan,
      fallback: await _menuService.getMacroLocals(
        propertyType: propertyType,
        subtipo: subtipo,
      ),
    );

    String? subjectContext = currentSelection.subjectContext;
    if (subjectContext == null && !showMacroLocalSelector) {
      subjectContext = initialSuggestedSelection.subjectContext;
    }
    if (subjectContext != null && !macroLocals.contains(subjectContext)) {
      subjectContext = macroLocals.isNotEmpty ? macroLocals.first : null;
    }

    final fetchedAmbientes =
        subjectContext == null
            ? const <String>[]
            : _executionPlanMenuOverlayService.environments(
              executionPlan,
              macroLocal: subjectContext,
              fallback: await _menuService.getAmbientes(
                propertyType: propertyType,
                subtipo: subtipo,
                macroLocal: subjectContext,
              ),
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

    if (initialLoad &&
        targetItem == null &&
        ambientes.isNotEmpty &&
        !showMacroLocalSelector) {
      targetItem = ambientes.first;
    }

    final elementos =
        (subjectContext == null || targetItem == null)
            ? const <String>[]
            : _executionPlanMenuOverlayService.elements(
              executionPlan,
              macroLocal: subjectContext,
              environment: targetItem,
              fallback: await _menuService.getElementos(
                propertyType: propertyType,
                subtipo: subtipo,
                macroLocal: subjectContext,
                ambiente: targetItem,
              ),
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

    final materiais =
        (subjectContext == null || targetItem == null || targetQualifier == null)
            ? const <String>[]
            : _executionPlanMenuOverlayService.materials(
              executionPlan,
              macroLocal: subjectContext,
              environment: targetItem,
              element: targetQualifier,
              fallback: await _menuService.getMateriais(
                propertyType: propertyType,
                subtipo: subtipo,
                macroLocal: subjectContext,
                ambiente: targetItem,
                elemento: targetQualifier,
              ),
            );

    final estados =
        (subjectContext == null || targetItem == null || targetQualifier == null)
            ? const <String>[]
            : _executionPlanMenuOverlayService.states(
              executionPlan,
              macroLocal: subjectContext,
              environment: targetItem,
              element: targetQualifier,
              fallback: await _menuService.getEstados(
                propertyType: propertyType,
                subtipo: subtipo,
                macroLocal: subjectContext,
                ambiente: targetItem,
                elemento: targetQualifier,
              ),
            );

    final currentMaterial = currentSelection.attributeText('inspection.material');
    String? resolvedMaterial = currentMaterial;
    if (resolvedMaterial != null && !materiais.contains(resolvedMaterial)) {
      resolvedMaterial = null;
    }

    String? targetCondition = currentSelection.targetCondition;
    if (targetCondition != null && !estados.contains(targetCondition)) {
      targetCondition = null;
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
      prediction: null,
      contextSuggestionSummary: null,
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
                currentSelection.domainAttributes.entries.where(
                  (entry) => entry.key != 'inspection.material',
                ),
              ),
        ),
      ),
    );
  }

  Future<InspectionCameraMenuViewState> resolveCanonical({
    required String assetType,
    String? assetSubtype,
    SmartExecutionPlan? executionPlan,
    List<String> currentKnownAmbientes = const <String>[],
    required bool showCaptureContextSelector,
    required bool initialLoad,
    required FlowSelection initialSuggestedSelection,
    required FlowSelection currentSelection,
  }) {
    return resolve(
      propertyType: assetType,
      subtipo: assetSubtype,
      executionPlan: executionPlan,
      currentKnownAmbientes: currentKnownAmbientes,
      showMacroLocalSelector: showCaptureContextSelector,
      initialLoad: initialLoad,
      initialSuggestedSelection: initialSuggestedSelection,
      currentSelection: currentSelection,
    );
  }
}
