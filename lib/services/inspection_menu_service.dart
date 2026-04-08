import '../config/checkin_step2_config.dart';
import '../config/inspection_menu_package.dart';
import '../models/inspection_menu_intelligence_models.dart';
import 'checkin_dynamic_config_service.dart';
import 'inspection_menu_catalog_service.dart';
import 'inspection_menu_document_loader.dart';
import 'inspection_menu_document_merge_resolver.dart';
import 'inspection_menu_intelligence_service.dart';
import 'inspection_menu_state_store.dart';

class InspectionMenuService {
  InspectionMenuService._();

  static final InspectionMenuService instance = InspectionMenuService._();

  static const String _assetPath = 'assets/config/menu_update_package_v1.json';
  static const String _usageKey = 'inspection_menu_usage_v3';
  static const String _predictionKey = 'inspection_menu_prediction_v3';

  InspectionMenuPackage? _package;
  Future<void>? _loading;
  final InspectionMenuDocumentLoader _documentLoader =
      InspectionMenuDocumentLoader.instance;
  final InspectionMenuDocumentMergeResolver _mergeResolver =
      InspectionMenuDocumentMergeResolver.instance;
  final InspectionMenuStateStore _stateStore = InspectionMenuStateStore.instance;
  final InspectionMenuCatalogService _catalogService =
      InspectionMenuCatalogService.instance;
  final InspectionMenuIntelligenceService _intelligenceService =
      InspectionMenuIntelligenceService.instance;

  Future<void> ensureLoaded() {
    return _loading ??= _load();
  }

  Future<void> reload() async {
    _loading = null;
    _package = null;
    _stateStore.reset();
    await ensureLoaded();
  }

  Future<void> _load() async {
    final documents = await _documentLoader.load(
      assetPath: _assetPath,
      loadDeveloperDocument:
          CheckinDynamicConfigService.instance.loadDeveloperMockDocument,
    );

    try {
      final mergedDocument = _mergeResolver.merge(
        base: documents.assetDocument,
        override: documents.developerDocument,
      );
      if (mergedDocument != null) {
        _package = InspectionMenuPackage.fromJson(mergedDocument);
      } else {
        _package = InspectionMenuPackage.fallback();
      }
    } catch (_) {
      _package = InspectionMenuPackage.fallback();
    }

    await _stateStore.load(
      usageKey: _usageKey,
      predictionKey: _predictionKey,
    );
  }

  Future<void> registerUsage({
    required String scope,
    required String value,
  }) async {
    await ensureLoaded();
    _stateStore.registerUsage(key: _usageCompoundKey(scope, value));
    await _stateStore.persistUsage(_usageKey);
  }

  Future<void> registerCaptureProfile({
    required String propertyType,
    String? macroLocal,
    required String ambiente,
    String? elemento,
    String? material,
    String? estado,
  }) async {
    await ensureLoaded();

    final predictionPolicy =
        _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback();
    final featureFlags =
        _package?.featureFlags ?? const FeatureFlagsConfig.fallback();
    if (!featureFlags.enablePredictionV3 || !predictionPolicy.enabled) {
      return;
    }

    final key = _intelligenceService.predictionContextKey(
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
    );

    _stateStore.registerPrediction(
      key: key,
      elemento: elemento,
      material: material,
      estado: estado,
    );

    final usageSnapshot = _stateStore.usageSnapshot();
    _intelligenceService.registerConfirmedUsage(
      usage: usageSnapshot,
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
      elemento: elemento,
      material: material,
      estado: estado,
    );
    _stateStore.replaceUsageFromSnapshot(usageSnapshot);

    await _stateStore.persistPrediction(_predictionKey);
    await _stateStore.persistUsage(_usageKey);
  }

  Future<SuggestedCameraContext?> getSuggestedContext({
    required String propertyType,
    List<String> availableMacroLocals = const [],
    String? macroLocal,
    List<String> availableAmbientes = const [],
  }) async {
    await ensureLoaded();

    return _intelligenceService.getSuggestedContext(
      featureFlags:
          _package?.featureFlags ?? const FeatureFlagsConfig.fallback(),
      predictionPolicy:
          _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback(),
      usage: _stateStore.usageSnapshot(),
      propertyType: propertyType,
      availableMacroLocals: availableMacroLocals,
      macroLocal: macroLocal,
      availableAmbientes: availableAmbientes,
    );
  }

  Future<PredictedSelection?> getPrediction({
    required String propertyType,
    String? macroLocal,
    required String ambiente,
    List<String> availableElementos = const [],
    List<String> availableMateriais = const [],
    List<String> availableEstados = const [],
  }) async {
    await ensureLoaded();

    return _intelligenceService.getPrediction(
      featureFlags:
          _package?.featureFlags ?? const FeatureFlagsConfig.fallback(),
      predictionPolicy:
          _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback(),
      prediction: _stateStore.predictionSnapshot(),
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
      availableElementos: availableElementos,
      availableMateriais: availableMateriais,
      availableEstados: availableEstados,
    );
  }

  Future<List<String>> getRecentAmbienteSuggestions({
    required String propertyType,
    required String macroLocal,
    List<String> availableAmbientes = const [],
  }) async {
    await ensureLoaded();

    return _intelligenceService.getRecentAmbienteSuggestions(
      featureFlags:
          _package?.featureFlags ?? const FeatureFlagsConfig.fallback(),
      predictionPolicy:
          _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback(),
      usage: _stateStore.usageSnapshot(),
      propertyType: propertyType,
      macroLocal: macroLocal,
      availableAmbientes: availableAmbientes,
    );
  }

  Future<List<String>> getRecentElementSuggestions({
    required String propertyType,
    String? macroLocal,
    required String ambiente,
    List<String> availableElementos = const [],
  }) async {
    await ensureLoaded();

    return _intelligenceService.getRecentElementSuggestions(
      featureFlags:
          _package?.featureFlags ?? const FeatureFlagsConfig.fallback(),
      predictionPolicy:
          _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback(),
      prediction: _stateStore.predictionSnapshot(),
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
      availableElementos: availableElementos,
    );
  }

  Future<List<CheckinStep2PhotoFieldConfig>> sortPhotoFields({
    required TipoImovel tipoImovel,
    required List<CheckinStep2PhotoFieldConfig> defaults,
  }) async {
    await ensureLoaded();
    final orderedIds =
        _package?.orderedPhotoFieldsFor(tipoImovel.name) ?? const <String>[];
    if (orderedIds.isEmpty) return defaults;

    final fieldMap = {for (final field in defaults) field.id: field};
    final ordered = <CheckinStep2PhotoFieldConfig>[];

    for (final id in orderedIds) {
      final field = fieldMap.remove(id);
      if (field != null) {
        ordered.add(field);
      }
    }

    for (final field in defaults) {
      if (fieldMap.containsKey(field.id)) {
        ordered.add(fieldMap.remove(field.id)!);
      }
    }

    return ordered;
  }

  Future<List<String>> getMacroLocals({required String propertyType}) async {
    await ensureLoaded();
    return _catalogService.macroLocals(
      package: _package,
      usage: _stateStore.usageSnapshot(),
      propertyType: propertyType,
    );
  }

  Future<List<String>> getCameraLevelOrder({
    required String propertyType,
    String? subtipo,
  }) async {
    await ensureLoaded();
    final levels = _package?.cameraLevelsFor(
      propertyType: propertyType,
      subtipo: subtipo,
    );
    if (levels == null || levels.isEmpty) {
      return const <String>[
        'macroLocal',
        'ambiente',
        'elemento',
        'material',
        'estado',
      ];
    }

    final result = <String>[];
    for (final level in levels) {
      final id = level.id.trim();
      if (id.isEmpty) continue;
      result.add(id);
    }

    return result.isNotEmpty
        ? result
        : const <String>[
          'macroLocal',
          'ambiente',
          'elemento',
          'material',
          'estado',
        ];
  }

  Future<List<ConfigLevelDefinition>> getCameraLevels({
    required String propertyType,
    String? subtipo,
  }) async {
    await ensureLoaded();
    final levels = _package?.cameraLevelsFor(
      propertyType: propertyType,
      subtipo: subtipo,
    );
    if (levels == null || levels.isEmpty) {
      return const <ConfigLevelDefinition>[];
    }
    return levels;
  }

  Future<List<String>> getAmbientes({
    required String propertyType,
    required String macroLocal,
  }) async {
    await ensureLoaded();
    return _catalogService.ambientes(
      package: _package,
      usage: _stateStore.usageSnapshot(),
      propertyType: propertyType,
      macroLocal: macroLocal,
    );
  }

  Future<List<String>> getElementos({
    required String propertyType,
    required String macroLocal,
    required String ambiente,
  }) async {
    await ensureLoaded();
    return _catalogService.elementos(
      package: _package,
      usage: _stateStore.usageSnapshot(),
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
    );
  }

  Future<List<String>> getMateriais({
    required String propertyType,
    required String macroLocal,
    required String ambiente,
    required String elemento,
  }) async {
    await ensureLoaded();
    return _catalogService.materiais(
      package: _package,
      usage: _stateStore.usageSnapshot(),
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
      elemento: elemento,
    );
  }

  Future<List<String>> getEstados({
    required String propertyType,
    required String macroLocal,
    required String ambiente,
    required String elemento,
  }) async {
    await ensureLoaded();
    return _catalogService.estados(
      package: _package,
      usage: _stateStore.usageSnapshot(),
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
      elemento: elemento,
    );
  }

  String _usageCompoundKey(String scope, String value) => '$scope::$value';
}
