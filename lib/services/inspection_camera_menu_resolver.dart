import '../models/inspection_camera_menu_view_state.dart';
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
    required InspectionCaptureContext initialSuggestedContext,
    required InspectionCaptureContext currentContext,
  }) async {
    final macroLocals = await _menuService.getMacroLocals(
      propertyType: propertyType,
    );

    String? macroLocal = currentContext.macroLocal;
    String? contextSuggestionSummary;

    if (macroLocal == null && !showMacroLocalSelector) {
      macroLocal = initialSuggestedContext.macroLocal;
    }

    if ((macroLocal == null || macroLocal.trim().isEmpty) &&
        showMacroLocalSelector) {
      final suggestedContext = await _menuService.getSuggestedContext(
        propertyType: propertyType,
        availableMacroLocals: macroLocals,
      );
      if (suggestedContext?.macroLocal != null) {
        macroLocal = suggestedContext!.macroLocal!;
        contextSuggestionSummary =
            'Área da foto sugerida com base no histórico: $macroLocal';
      }
    }

    if (macroLocal != null && !macroLocals.contains(macroLocal)) {
      macroLocal = macroLocals.isNotEmpty ? macroLocals.first : null;
    }

    final ambientes =
        macroLocal == null
            ? const <String>[]
            : await _menuService.getAmbientes(
              propertyType: propertyType,
              macroLocal: macroLocal,
            );

    final recentAmbientes =
        macroLocal == null
            ? const <String>[]
            : await _menuService.getRecentAmbienteSuggestions(
              propertyType: propertyType,
              macroLocal: macroLocal,
              availableAmbientes: ambientes,
            );

    String? ambiente = currentContext.ambiente;
    if (ambiente != null && !ambientes.contains(ambiente)) {
      ambiente = null;
    }

    if ((ambiente == null || ambiente.trim().isEmpty) && macroLocal != null) {
      final suggestedContext = await _menuService.getSuggestedContext(
        propertyType: propertyType,
        macroLocal: macroLocal,
        availableAmbientes: ambientes,
      );
      if (initialSuggestedContext.ambiente == null &&
          suggestedContext?.ambiente != null) {
        ambiente = suggestedContext!.ambiente!;
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
            : await _menuService.getElementos(
              propertyType: propertyType,
              macroLocal: macroLocal,
              ambiente: ambiente,
            );

    final recentElementos =
        (macroLocal == null || ambiente == null)
            ? const <String>[]
            : await _menuService.getRecentElementSuggestions(
              propertyType: propertyType,
              macroLocal: macroLocal,
              ambiente: ambiente,
              availableElementos: elementos,
            );

    String? elemento = currentContext.elemento;
    if (elemento != null && !elementos.contains(elemento)) {
      elemento = elementos.isNotEmpty ? elementos.first : null;
    }

    var prediction =
        (macroLocal == null || ambiente == null)
            ? null
            : await _menuService.getPrediction(
              propertyType: propertyType,
              macroLocal: macroLocal,
              ambiente: ambiente,
              availableElementos: elementos,
            );

    if (elemento == null &&
        initialSuggestedContext.elemento == null &&
        prediction?.elemento != null &&
        elementos.contains(prediction!.elemento)) {
      elemento = prediction.elemento;
    }

    final materiais =
        (macroLocal == null || ambiente == null || elemento == null)
            ? const <String>[]
            : await _menuService.getMateriais(
              propertyType: propertyType,
              macroLocal: macroLocal,
              ambiente: ambiente,
              elemento: elemento,
            );
    final estados =
        (macroLocal == null || ambiente == null || elemento == null)
            ? const <String>[]
            : await _menuService.getEstados(
              propertyType: propertyType,
              macroLocal: macroLocal,
              ambiente: ambiente,
              elemento: elemento,
            );

    prediction =
        (macroLocal == null || ambiente == null)
            ? null
            : await _menuService.getPrediction(
              propertyType: propertyType,
              macroLocal: macroLocal,
              ambiente: ambiente,
              availableElementos: elementos,
              availableMateriais: materiais,
              availableEstados: estados,
            );

    String? material = currentContext.material;
    if (material != null && !materiais.contains(material)) {
      material = null;
    }
    if (material == null &&
        prediction?.material != null &&
        materiais.contains(prediction!.material)) {
      material = prediction.material;
    }

    String? estado = currentContext.estado;
    if (estado != null && !estados.contains(estado)) {
      estado = null;
    }
    if (estado == null &&
        prediction?.estado != null &&
        estados.contains(prediction!.estado)) {
      estado = prediction.estado;
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
      currentContext: InspectionCaptureContext(
        macroLocal: macroLocal,
        ambiente: ambiente,
        ambienteBase: parsed.baseLabel,
        ambienteInstanceIndex: parsed.instanceIndex,
        elemento: elemento,
        material: material,
        estado: estado,
      ),
    );
  }
}
