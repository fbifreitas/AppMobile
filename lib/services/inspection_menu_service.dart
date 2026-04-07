import '../config/checkin_step2_config.dart';
import '../config/inspection_menu_package.dart';
import '../models/flow_selection.dart';
import '../models/inspection_menu_intelligence_models.dart';
import 'checkin_dynamic_config_service.dart';
import 'inspection_menu_catalog_service.dart';
import 'inspection_menu_document_loader.dart';
import 'inspection_menu_document_merge_resolver.dart';
import 'inspection_menu_intelligence_service.dart';
import 'inspection_menu_preferences_store.dart';

class _UsageEntry {
  int count;
  DateTime? lastUsedAt;

  _UsageEntry({required this.count, required this.lastUsedAt});

  factory _UsageEntry.fromJson(Map<String, dynamic> json) {
    return _UsageEntry(
      count: json['count'] as int? ?? 0,
      lastUsedAt:
          json['lastUsedAt'] != null
              ? DateTime.tryParse(json['lastUsedAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'count': count,
    'lastUsedAt': lastUsedAt?.toIso8601String(),
  };
}

class _PredictionEntry {
  int captures;
  DateTime? lastUsedAt;
  Map<String, int> elementos;
  Map<String, int> materiais;
  Map<String, int> estados;

  _PredictionEntry({
    required this.captures,
    required this.lastUsedAt,
    required this.elementos,
    required this.materiais,
    required this.estados,
  });

  factory _PredictionEntry.fromJson(Map<String, dynamic> json) {
    Map<String, int> intMap(Object? value) {
      final map = Map<String, dynamic>.from(value as Map? ?? const {});
      return map.map((key, val) => MapEntry(key, (val as num).toInt()));
    }

    return _PredictionEntry(
      captures: (json['captures'] as num?)?.toInt() ?? 0,
      lastUsedAt:
          json['lastUsedAt'] != null
              ? DateTime.tryParse(json['lastUsedAt'] as String)
              : null,
      elementos: intMap(json['elementos']),
      materiais: intMap(json['materiais']),
      estados: intMap(json['estados']),
    );
  }

  Map<String, dynamic> toJson() => {
    'captures': captures,
    'lastUsedAt': lastUsedAt?.toIso8601String(),
    'elementos': elementos,
    'materiais': materiais,
    'estados': estados,
  };
}

class InspectionMenuService {
  InspectionMenuService._();

  static final InspectionMenuService instance = InspectionMenuService._();

  static const String _assetPath = 'assets/config/menu_update_package_v1.json';
  static const String _usageKey = 'inspection_menu_usage_v3';
  static const String _predictionKey = 'inspection_menu_prediction_v3';

  InspectionMenuPackage? _package;
  Future<void>? _loading;
  Map<String, _UsageEntry> _usage = {};
  Map<String, _PredictionEntry> _prediction = {};
  final InspectionMenuDocumentLoader _documentLoader =
      InspectionMenuDocumentLoader.instance;
  final InspectionMenuDocumentMergeResolver _mergeResolver =
      InspectionMenuDocumentMergeResolver.instance;
  final InspectionMenuPreferencesStore _preferencesStore =
      InspectionMenuPreferencesStore.instance;
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
    _usage = {};
    _prediction = {};
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

    try {
      final snapshot = await _preferencesStore.load(
        usageKey: _usageKey,
        predictionKey: _predictionKey,
      );
      _usage = snapshot.usage.map(
        (key, value) => MapEntry(
          key,
          _UsageEntry.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      );
      _prediction = snapshot.prediction.map(
        (key, value) => MapEntry(
          key,
          _PredictionEntry.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      );
    } catch (_) {
      _usage = {};
      _prediction = {};
    }
  }

  Future<void> registerUsage({
    required String scope,
    required String value,
  }) async {
    await ensureLoaded();
    final key = _usageCompoundKey(scope, value);
    final entry = _usage.putIfAbsent(
      key,
      () => _UsageEntry(count: 0, lastUsedAt: null),
    );
    entry.count += 1;
    entry.lastUsedAt = DateTime.now();
    await _persistUsage();
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

    final entry = _prediction.putIfAbsent(
      key,
      () => _PredictionEntry(
        captures: 0,
        lastUsedAt: null,
        elementos: {},
        materiais: {},
        estados: {},
      ),
    );

    entry.captures += 1;
    entry.lastUsedAt = DateTime.now();

    if (elemento != null && elemento.trim().isNotEmpty) {
      entry.elementos.update(elemento, (value) => value + 1, ifAbsent: () => 1);
    }
    if (material != null && material.trim().isNotEmpty) {
      entry.materiais.update(material, (value) => value + 1, ifAbsent: () => 1);
    }
    if (estado != null && estado.trim().isNotEmpty) {
      entry.estados.update(estado, (value) => value + 1, ifAbsent: () => 1);
    }

    final usageSnapshot = _usageSnapshot();
    _intelligenceService.registerConfirmedUsage(
      usage: usageSnapshot,
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
      elemento: elemento,
      material: material,
      estado: estado,
    );
    _replaceUsageFromSnapshot(usageSnapshot);

    await _persistPrediction();
    await _persistUsage();
  }

  Future<void> registerCaptureSelectionProfile({
    required String propertyType,
    required FlowSelection selection,
  }) {
    return _registerCaptureSelectionProfileInternal(
      propertyType: propertyType,
      selection: selection,
    );
  }

  Future<String?> getSuggestedMacroLocal({
    required String propertyType,
    List<String> availableMacroLocals = const [],
  }) async {
    await ensureLoaded();

    return _intelligenceService.getSuggestedMacroLocal(
      featureFlags:
          _package?.featureFlags ?? const FeatureFlagsConfig.fallback(),
      predictionPolicy:
          _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback(),
      usage: _usageSnapshot(),
      propertyType: propertyType,
      availableMacroLocals: availableMacroLocals,
    );
  }

  Future<String?> getSuggestedAmbiente({
    required String propertyType,
    required String macroLocal,
    List<String> availableAmbientes = const [],
  }) async {
    await ensureLoaded();

    return _intelligenceService.getSuggestedAmbiente(
      featureFlags:
          _package?.featureFlags ?? const FeatureFlagsConfig.fallback(),
      predictionPolicy:
          _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback(),
      usage: _usageSnapshot(),
      propertyType: propertyType,
      macroLocal: macroLocal,
      availableAmbientes: availableAmbientes,
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
      usage: _usageSnapshot(),
      propertyType: propertyType,
      macroLocal: macroLocal,
      availableAmbientes: availableAmbientes,
    );
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
      usage: _usageSnapshot(),
      propertyType: propertyType,
      availableMacroLocals: availableMacroLocals,
      macroLocal: macroLocal,
      availableAmbientes: availableAmbientes,
    );
  }

  Future<SuggestedCameraContext?> getSuggestedSelection({
    required String propertyType,
    FlowSelection currentSelection = FlowSelection.empty,
    List<String> availableSubjectContexts = const [],
    List<String> availableTargetItems = const [],
  }) {
    return Future<SuggestedCameraContext?>.value(
      _intelligenceService.getSuggestedSelection(
        featureFlags:
            _package?.featureFlags ?? const FeatureFlagsConfig.fallback(),
        predictionPolicy:
            _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback(),
        usage: _usageSnapshot(),
        propertyType: propertyType,
        currentSelection: currentSelection,
        availableSubjectContexts: availableSubjectContexts,
        availableTargetItems: availableTargetItems,
      ),
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
      prediction: _predictionSnapshot(),
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
      availableElementos: availableElementos,
      availableMateriais: availableMateriais,
      availableEstados: availableEstados,
    );
  }

  Future<PredictedSelection?> getPredictionForSelection({
    required String propertyType,
    required FlowSelection selection,
    List<String> availableTargetQualifiers = const [],
    List<String> availableTargetQualifierMaterials = const [],
    List<String> availableTargetConditions = const [],
  }) {
    return Future<PredictedSelection?>.value(
      _intelligenceService.getPredictionForSelection(
        featureFlags:
            _package?.featureFlags ?? const FeatureFlagsConfig.fallback(),
        predictionPolicy:
            _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback(),
        prediction: _predictionSnapshot(),
        propertyType: propertyType,
        selection: selection,
        availableTargetQualifiers: availableTargetQualifiers,
        availableTargetQualifierMaterials: availableTargetQualifierMaterials,
        availableTargetConditions: availableTargetConditions,
      ),
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
      prediction: _predictionSnapshot(),
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
      availableElementos: availableElementos,
    );
  }

  Future<List<String>> getRecentTargetItemSuggestions({
    required String propertyType,
    required String subjectContext,
    List<String> availableTargetItems = const [],
  }) {
    return Future<List<String>>.value(
      _intelligenceService.getRecentTargetItemSuggestions(
        featureFlags:
            _package?.featureFlags ?? const FeatureFlagsConfig.fallback(),
        predictionPolicy:
            _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback(),
        usage: _usageSnapshot(),
        propertyType: propertyType,
        subjectContext: subjectContext,
        availableTargetItems: availableTargetItems,
      ),
    );
  }

  Future<List<String>> getRecentTargetQualifierSuggestions({
    required String propertyType,
    required FlowSelection selection,
    List<String> availableTargetQualifiers = const [],
  }) {
    return Future<List<String>>.value(
      _intelligenceService.getRecentTargetQualifierSuggestions(
        featureFlags:
            _package?.featureFlags ?? const FeatureFlagsConfig.fallback(),
        predictionPolicy:
            _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback(),
        prediction: _predictionSnapshot(),
        propertyType: propertyType,
        selection: selection,
        availableTargetQualifiers: availableTargetQualifiers,
      ),
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
      usage: _usageSnapshot(),
      propertyType: propertyType,
    );
  }

  Future<List<String>> getSubjectContexts({required String propertyType}) {
    return Future<List<String>>.value(
      _catalogService.subjectContexts(
        package: _package,
        usage: _usageSnapshot(),
        propertyType: propertyType,
      ),
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
      if (id.isEmpty) {
        continue;
      }
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
      usage: _usageSnapshot(),
      propertyType: propertyType,
      macroLocal: macroLocal,
    );
  }

  Future<List<String>> getTargetItems({
    required String propertyType,
    required String subjectContext,
  }) {
    return Future<List<String>>.value(
      _catalogService.targetItems(
        package: _package,
        usage: _usageSnapshot(),
        propertyType: propertyType,
        subjectContext: subjectContext,
      ),
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
      usage: _usageSnapshot(),
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
    );
  }

  Future<List<String>> getTargetQualifiers({
    required String propertyType,
    required FlowSelection selection,
  }) {
    return Future<List<String>>.value(
      _catalogService.targetQualifiers(
        package: _package,
        usage: _usageSnapshot(),
        propertyType: propertyType,
        selection: selection,
      ),
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
      usage: _usageSnapshot(),
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
      elemento: elemento,
    );
  }

  Future<List<String>> getTargetQualifierMaterials({
    required String propertyType,
    required FlowSelection selection,
  }) {
    return Future<List<String>>.value(
      _catalogService.targetQualifierMaterials(
        package: _package,
        usage: _usageSnapshot(),
        propertyType: propertyType,
        selection: selection,
      ),
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
      usage: _usageSnapshot(),
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
      elemento: elemento,
    );
  }

  Future<List<String>> getTargetConditions({
    required String propertyType,
    required FlowSelection selection,
  }) {
    return Future<List<String>>.value(
      _catalogService.targetConditions(
        package: _package,
        usage: _usageSnapshot(),
        propertyType: propertyType,
        selection: selection,
      ),
    );
  }

  Future<void> _registerCaptureSelectionProfileInternal({
    required String propertyType,
    required FlowSelection selection,
  }) async {
    await ensureLoaded();

    final targetItem = selection.targetItem;
    if (targetItem == null || targetItem.trim().isEmpty) {
      return;
    }

    final predictionPolicy =
        _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback();
    final featureFlags =
        _package?.featureFlags ?? const FeatureFlagsConfig.fallback();
    if (!featureFlags.enablePredictionV3 || !predictionPolicy.enabled) {
      return;
    }

    final key = _intelligenceService.predictionContextKey(
      propertyType: propertyType,
      macroLocal: selection.subjectContext,
      ambiente: targetItem,
    );

    final entry = _prediction.putIfAbsent(
      key,
      () => _PredictionEntry(
        captures: 0,
        lastUsedAt: null,
        elementos: {},
        materiais: {},
        estados: {},
      ),
    );

    entry.captures += 1;
    entry.lastUsedAt = DateTime.now();

    final targetQualifier = selection.targetQualifier;
    final material = selection.attributeText('inspection.material');
    final targetCondition = selection.targetCondition;

    if (targetQualifier != null && targetQualifier.trim().isNotEmpty) {
      entry.elementos.update(
        targetQualifier,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    if (material != null && material.trim().isNotEmpty) {
      entry.materiais.update(material, (value) => value + 1, ifAbsent: () => 1);
    }
    if (targetCondition != null && targetCondition.trim().isNotEmpty) {
      entry.estados.update(
        targetCondition,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final usageSnapshot = _usageSnapshot();
    _intelligenceService.registerConfirmedSelectionUsage(
      usage: usageSnapshot,
      propertyType: propertyType,
      selection: selection,
    );
    _replaceUsageFromSnapshot(usageSnapshot);

    await _persistPrediction();
    await _persistUsage();
  }

  String _usageCompoundKey(String scope, String value) => '$scope::$value';

  Future<void> _persistUsage() async {
    await _preferencesStore.persistUsage(
      usageKey: _usageKey,
      usage: _usage.map((key, value) => MapEntry(key, value.toJson())),
    );
  }

  Future<void> _persistPrediction() async {
    await _preferencesStore.persistPrediction(
      predictionKey: _predictionKey,
      prediction: _prediction.map((key, value) => MapEntry(key, value.toJson())),
    );
  }

  Map<String, dynamic> _usageSnapshot() =>
      _usage.map((key, value) => MapEntry(key, value.toJson()));

  Map<String, dynamic> _predictionSnapshot() =>
      _prediction.map((key, value) => MapEntry(key, value.toJson()));

  void _replaceUsageFromSnapshot(Map<String, dynamic> snapshot) {
    _usage = snapshot.map(
      (key, value) => MapEntry(
        key,
        _UsageEntry.fromJson(Map<String, dynamic>.from(value as Map)),
      ),
    );
  }
}
