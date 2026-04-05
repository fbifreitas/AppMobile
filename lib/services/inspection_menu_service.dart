import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/checkin_step2_config.dart';
import '../config/inspection_menu_package.dart';
import 'checkin_dynamic_config_service.dart';

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

class PredictedSelection {
  final String? elemento;
  final String? material;
  final String? estado;
  final int captures;

  const PredictedSelection({
    this.elemento,
    this.material,
    this.estado,
    required this.captures,
  });

  bool get hasAnyValue =>
      (elemento != null && elemento!.trim().isNotEmpty) ||
      (material != null && material!.trim().isNotEmpty) ||
      (estado != null && estado!.trim().isNotEmpty);
}

class SuggestedCameraContext {
  final String? macroLocal;
  final String? ambiente;
  final int confidenceSignals;

  const SuggestedCameraContext({
    this.macroLocal,
    this.ambiente,
    required this.confidenceSignals,
  });

  bool get hasValue =>
      (macroLocal != null && macroLocal!.trim().isNotEmpty) ||
      (ambiente != null && ambiente!.trim().isNotEmpty);
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
    Map<String, dynamic>? assetDocument;
    Map<String, dynamic>? developerDocument;

    try {
      final raw = await rootBundle.loadString(_assetPath);
      assetDocument = Map<String, dynamic>.from(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      assetDocument = null;
    }

    try {
      developerDocument =
          await CheckinDynamicConfigService.instance
              .loadDeveloperMockDocument();
    } catch (_) {
      developerDocument = null;
    }

    try {
      final mergedDocument = _mergeDocuments(
        base: assetDocument,
        override: developerDocument,
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
      final prefs = await SharedPreferences.getInstance();
      final rawUsage = prefs.getString(_usageKey);
      if (rawUsage != null && rawUsage.trim().isNotEmpty) {
        final decoded = jsonDecode(rawUsage) as Map<String, dynamic>;
        _usage = decoded.map(
          (key, value) => MapEntry(
            key,
            _UsageEntry.fromJson(Map<String, dynamic>.from(value as Map)),
          ),
        );
      }

      final rawPrediction = prefs.getString(_predictionKey);
      if (rawPrediction != null && rawPrediction.trim().isNotEmpty) {
        final decoded = jsonDecode(rawPrediction) as Map<String, dynamic>;
        _prediction = decoded.map(
          (key, value) => MapEntry(
            key,
            _PredictionEntry.fromJson(Map<String, dynamic>.from(value as Map)),
          ),
        );
      }
    } catch (_) {
      _usage = {};
      _prediction = {};
    }
  }

  Map<String, dynamic>? _mergeDocuments({
    Map<String, dynamic>? base,
    Map<String, dynamic>? override,
  }) {
    if (base == null && override == null) return null;
    if (base == null) return Map<String, dynamic>.from(override!);
    if (override == null) return Map<String, dynamic>.from(base);

    final result = <String, dynamic>{};
    final keys = <String>{...base.keys, ...override.keys};

    for (final key in keys) {
      final baseValue = base[key];
      final overrideValue = override[key];

      if (baseValue is Map && overrideValue is Map) {
        result[key] = _mergeDocuments(
          base: Map<String, dynamic>.from(baseValue),
          override: Map<String, dynamic>.from(overrideValue),
        );
      } else if (override.containsKey(key)) {
        result[key] = overrideValue;
      } else {
        result[key] = baseValue;
      }
    }

    return result;
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

    final key = _predictionContextKey(
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

    _registerConfirmedUsage(
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
      elemento: elemento,
      material: material,
      estado: estado,
    );

    await _persistPrediction();
    await _persistUsage();
  }

  Future<String?> getSuggestedMacroLocal({
    required String propertyType,
    List<String> availableMacroLocals = const [],
  }) async {
    await ensureLoaded();

    final featureFlags =
        _package?.featureFlags ?? const FeatureFlagsConfig.fallback();
    final predictionPolicy =
        _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback();
    if (!featureFlags.enableContextBootstrapV4) {
      return null;
    }

    return _topConfirmedValue(
      scope: 'camera_confirmed.${propertyType.toLowerCase()}.macro',
      allowed: availableMacroLocals,
      minCount: predictionPolicy.minContextSuggestionCaptures,
    );
  }

  Future<String?> getSuggestedAmbiente({
    required String propertyType,
    required String macroLocal,
    List<String> availableAmbientes = const [],
  }) async {
    await ensureLoaded();

    final featureFlags =
        _package?.featureFlags ?? const FeatureFlagsConfig.fallback();
    final predictionPolicy =
        _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback();
    if (!featureFlags.enableContextBootstrapV4) {
      return null;
    }

    return _topConfirmedValue(
      scope:
          'camera_confirmed.${propertyType.toLowerCase()}.$macroLocal.ambiente',
      allowed: availableAmbientes,
      minCount: predictionPolicy.minContextSuggestionCaptures,
    );
  }

  Future<List<String>> getRecentAmbienteSuggestions({
    required String propertyType,
    required String macroLocal,
    List<String> availableAmbientes = const [],
  }) async {
    await ensureLoaded();

    final featureFlags =
        _package?.featureFlags ?? const FeatureFlagsConfig.fallback();
    final predictionPolicy =
        _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback();
    if (!featureFlags.enableRecentAmbienteSuggestionsV4) {
      return const <String>[];
    }

    return _topConfirmedValues(
      scope:
          'camera_confirmed.${propertyType.toLowerCase()}.$macroLocal.ambiente',
      allowed: availableAmbientes,
      limit: predictionPolicy.maxRecentAmbienteSuggestions,
    );
  }

  Future<SuggestedCameraContext?> getSuggestedContext({
    required String propertyType,
    List<String> availableMacroLocals = const [],
    String? macroLocal,
    List<String> availableAmbientes = const [],
  }) async {
    await ensureLoaded();

    String? resolvedMacro = macroLocal;
    var confidenceSignals = 0;

    if (resolvedMacro == null || resolvedMacro.trim().isEmpty) {
      resolvedMacro = await getSuggestedMacroLocal(
        propertyType: propertyType,
        availableMacroLocals: availableMacroLocals,
      );
      if (resolvedMacro != null) {
        confidenceSignals += 1;
      }
    }

    String? ambiente;
    if (resolvedMacro != null && resolvedMacro.trim().isNotEmpty) {
      ambiente = await getSuggestedAmbiente(
        propertyType: propertyType,
        macroLocal: resolvedMacro,
        availableAmbientes: availableAmbientes,
      );
      if (ambiente != null) {
        confidenceSignals += 1;
      }
    }

    final suggestion = SuggestedCameraContext(
      macroLocal: resolvedMacro,
      ambiente: ambiente,
      confidenceSignals: confidenceSignals,
    );

    return suggestion.hasValue ? suggestion : null;
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

    final predictionPolicy =
        _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback();
    final featureFlags =
        _package?.featureFlags ?? const FeatureFlagsConfig.fallback();
    if (!featureFlags.enablePredictionV3 || !predictionPolicy.enabled) {
      return null;
    }

    final entry =
        _prediction[_predictionContextKey(
          propertyType: propertyType,
          macroLocal: macroLocal,
          ambiente: ambiente,
        )];

    if (entry == null) return null;
    if (entry.captures < predictionPolicy.minContextCaptures) return null;
    if (entry.lastUsedAt != null) {
      final days = DateTime.now().difference(entry.lastUsedAt!).inDays;
      if (days > predictionPolicy.recencyWindowDays) return null;
    }

    final elemento =
        predictionPolicy.autoSelectElemento
            ? _pickBest(entry.elementos, allowed: availableElementos)
            : null;
    final material =
        predictionPolicy.autoSelectMaterial
            ? _pickBest(entry.materiais, allowed: availableMateriais)
            : null;
    final estado =
        predictionPolicy.autoSelectEstado
            ? _pickBest(entry.estados, allowed: availableEstados)
            : null;

    final prediction = PredictedSelection(
      elemento: elemento,
      material: material,
      estado: estado,
      captures: entry.captures,
    );

    return prediction.hasAnyValue ? prediction : null;
  }

  Future<List<String>> getRecentElementSuggestions({
    required String propertyType,
    String? macroLocal,
    required String ambiente,
    List<String> availableElementos = const [],
  }) async {
    await ensureLoaded();

    final predictionPolicy =
        _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback();
    final featureFlags =
        _package?.featureFlags ?? const FeatureFlagsConfig.fallback();
    if (!featureFlags.enableRecentSuggestionsV3) {
      return const <String>[];
    }

    final entry =
        _prediction[_predictionContextKey(
          propertyType: propertyType,
          macroLocal: macroLocal,
          ambiente: ambiente,
        )];
    if (entry == null) return const <String>[];

    final allowedSet = availableElementos.toSet();
    final sorted =
        entry.elementos.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final results = <String>[];
    for (final item in sorted) {
      if (allowedSet.isNotEmpty && !allowedSet.contains(item.key)) continue;
      if (!results.contains(item.key)) {
        results.add(item.key);
      }
      if (results.length >= predictionPolicy.maxRecentSuggestions) break;
    }
    return results;
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
    final config = _package?.configFor(propertyType);
    final options = config?.macroLocals ?? _fallbackMacroLocals(propertyType);
    return _rankOptions(
      options: options,
      scope: 'camera.${propertyType.toLowerCase()}.macro',
    ).map((item) => item.label).toList();
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
    final config = _package?.configFor(propertyType);
    final selectedMacro = _firstWhereOrNull<MacroLocalOption>(
      config?.macroLocals ?? const <MacroLocalOption>[],
      (item) => item.label == macroLocal,
    );

    final options =
        selectedMacro?.ambientes ??
        _fallbackAmbientes(propertyType, macroLocal);

    return _rankOptions(
      options: options,
      scope: 'camera.${propertyType.toLowerCase()}.$macroLocal.ambiente',
    ).map((item) => item.label).toList();
  }

  Future<List<String>> getElementos({
    required String propertyType,
    required String macroLocal,
    required String ambiente,
  }) async {
    await ensureLoaded();
    final config = _package?.configFor(propertyType);
    final selectedMacro = _firstWhereOrNull<MacroLocalOption>(
      config?.macroLocals ?? const <MacroLocalOption>[],
      (item) => item.label == macroLocal,
    );
    final selectedAmbiente = _firstWhereOrNull<RankedMenuOption>(
      selectedMacro?.ambientes ?? const <RankedMenuOption>[],
      (item) => item.label == ambiente,
    );

    final options =
        selectedAmbiente?.elements ??
        _fallbackElementos(propertyType, macroLocal, ambiente);

    return _rankOptions(
      options: options,
      scope:
          'camera.${propertyType.toLowerCase()}.$macroLocal.$ambiente.elemento',
    ).map((item) => item.label).toList();
  }

  Future<List<String>> getMateriais({
    required String propertyType,
    required String macroLocal,
    required String ambiente,
    required String elemento,
  }) async {
    await ensureLoaded();
    final selectedElement = _findSelectedElement(
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
      elemento: elemento,
    );

    final options = selectedElement?.materials ?? _fallbackMateriais(elemento);
    return _rankOptions(
      options: options,
      scope:
          'camera.${propertyType.toLowerCase()}.$macroLocal.$ambiente.$elemento.material',
    ).map((item) => item.label).toList();
  }

  Future<List<String>> getEstados({
    required String propertyType,
    required String macroLocal,
    required String ambiente,
    required String elemento,
  }) async {
    await ensureLoaded();
    final selectedElement = _findSelectedElement(
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
      elemento: elemento,
    );

    final options = selectedElement?.states ?? _fallbackEstados();
    return _rankOptions(
      options: options,
      scope:
          'camera.${propertyType.toLowerCase()}.$macroLocal.$ambiente.$elemento.estado',
    ).map((item) => item.label).toList();
  }

  RankedMenuOption? _findSelectedElement({
    required String propertyType,
    required String macroLocal,
    required String ambiente,
    required String elemento,
  }) {
    final config = _package?.configFor(propertyType);
    final selectedMacro = _firstWhereOrNull<MacroLocalOption>(
      config?.macroLocals ?? const <MacroLocalOption>[],
      (item) => item.label == macroLocal,
    );
    final selectedAmbiente = _firstWhereOrNull<RankedMenuOption>(
      selectedMacro?.ambientes ?? const <RankedMenuOption>[],
      (item) => item.label == ambiente,
    );
    return _firstWhereOrNull<RankedMenuOption>(
      selectedAmbiente?.elements ?? const <RankedMenuOption>[],
      (item) => item.label == elemento,
    );
  }

  T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T item) test) {
    for (final value in values) {
      if (test(value)) return value;
    }
    return null;
  }

  List<T> _rankOptions<T extends RankedMenuOption>({
    required List<T> options,
    required String scope,
  }) {
    final pinnedTop = <T>[];
    final middle = <T>[];
    final pinnedBottom = <T>[];

    for (final option in options) {
      if (option.pinnedTop) {
        pinnedTop.add(option);
      } else if (option.pinnedBottom) {
        pinnedBottom.add(option);
      } else {
        middle.add(option);
      }
    }

    int compareByScore(T a, T b) {
      final aScore = _score(option: a, scope: scope);
      final bScore = _score(option: b, scope: scope);
      return bScore.compareTo(aScore);
    }

    pinnedTop.sort(compareByScore);
    middle.sort(compareByScore);
    pinnedBottom.sort(compareByScore);

    return [...pinnedTop, ...middle, ...pinnedBottom];
  }

  double _score({required RankedMenuOption option, required String scope}) {
    final policy =
        _package?.rankingPolicy ?? const RankingPolicyConfig.fallback();
    final editorial = option.baseScore * policy.editorialWeight;

    final entry = _usage[_usageCompoundKey(scope, option.label)];
    if (entry == null) {
      return editorial;
    }

    final usage =
        entry.count >= policy.minUsesToReorder
            ? entry.count * 10 * policy.localUsageWeight
            : 0.0;

    double recency = 0;
    if (entry.lastUsedAt != null) {
      final days = DateTime.now().difference(entry.lastUsedAt!).inDays;
      if (days <= policy.decayDays) {
        recency =
            ((policy.decayDays - days) / policy.decayDays) *
            100 *
            policy.recencyWeight;
      }
    }

    return editorial + usage + recency;
  }

  String _usageCompoundKey(String scope, String value) => '$scope::$value';

  String _predictionContextKey({
    required String propertyType,
    String? macroLocal,
    required String ambiente,
  }) {
    final normalizedType = propertyType.trim().toLowerCase();
    final normalizedMacro = (macroLocal ?? '').trim().toLowerCase();
    final normalizedAmbiente = ambiente.trim().toLowerCase();
    return 'prediction::$normalizedType::$normalizedMacro::$normalizedAmbiente';
  }

  String? _pickBest(
    Map<String, int> counts, {
    List<String> allowed = const [],
  }) {
    if (counts.isEmpty) return null;
    final allowedSet = allowed.toSet();
    final entries =
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in entries) {
      if (allowedSet.isEmpty || allowedSet.contains(entry.key)) {
        return entry.key;
      }
    }
    return null;
  }

  void _registerConfirmedUsage({
    required String propertyType,
    String? macroLocal,
    required String ambiente,
    String? elemento,
    String? material,
    String? estado,
  }) {
    final normalizedType = propertyType.toLowerCase();

    if (macroLocal != null && macroLocal.trim().isNotEmpty) {
      _incrementUsage(
        scope: 'camera_confirmed.$normalizedType.macro',
        value: macroLocal,
      );

      _incrementUsage(
        scope: 'camera_confirmed.$normalizedType.$macroLocal.ambiente',
        value: ambiente,
      );
    }

    if (elemento != null &&
        elemento.trim().isNotEmpty &&
        macroLocal != null &&
        macroLocal.trim().isNotEmpty) {
      _incrementUsage(
        scope:
            'camera_confirmed.$normalizedType.$macroLocal.$ambiente.elemento',
        value: elemento,
      );
    }

    if (material != null &&
        material.trim().isNotEmpty &&
        elemento != null &&
        elemento.trim().isNotEmpty) {
      _incrementUsage(
        scope:
            'camera_confirmed.$normalizedType.$macroLocal.$ambiente.$elemento.material',
        value: material,
      );
    }

    if (estado != null &&
        estado.trim().isNotEmpty &&
        elemento != null &&
        elemento.trim().isNotEmpty) {
      _incrementUsage(
        scope:
            'camera_confirmed.$normalizedType.$macroLocal.$ambiente.$elemento.estado',
        value: estado,
      );
    }
  }

  void _incrementUsage({required String scope, required String value}) {
    final key = _usageCompoundKey(scope, value);
    final entry = _usage.putIfAbsent(
      key,
      () => _UsageEntry(count: 0, lastUsedAt: null),
    );
    entry.count += 1;
    entry.lastUsedAt = DateTime.now();
  }

  String? _topConfirmedValue({
    required String scope,
    List<String> allowed = const [],
    required int minCount,
  }) {
    final values = _topConfirmedValues(
      scope: scope,
      allowed: allowed,
      limit: 1,
    );
    if (values.isEmpty) {
      return null;
    }

    final key = _usageCompoundKey(scope, values.first);
    final entry = _usage[key];
    if (entry == null || entry.count < minCount) {
      return null;
    }

    return values.first;
  }

  List<String> _topConfirmedValues({
    required String scope,
    List<String> allowed = const [],
    required int limit,
  }) {
    final prefix = '$scope::';
    final allowedSet = allowed.toSet();
    final entries =
        _usage.entries.where((entry) => entry.key.startsWith(prefix)).where((
            entry,
          ) {
            if (allowedSet.isEmpty) {
              return true;
            }
            final value = entry.key.substring(prefix.length);
            return allowedSet.contains(value);
          }).toList()
          ..sort((a, b) {
            final countCompare = b.value.count.compareTo(a.value.count);
            if (countCompare != 0) {
              return countCompare;
            }

            final aDate =
                a.value.lastUsedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                b.value.lastUsedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

    return entries
        .take(limit)
        .map((entry) => entry.key.substring(prefix.length))
        .toList();
  }

  Future<void> _persistUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _usageKey,
      jsonEncode(_usage.map((key, value) => MapEntry(key, value.toJson()))),
    );
  }

  Future<void> _persistPrediction() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _predictionKey,
      jsonEncode(
        _prediction.map((key, value) => MapEntry(key, value.toJson())),
      ),
    );
  }

  List<MacroLocalOption> _fallbackMacroLocals(String propertyType) {
    switch (propertyType.trim().toLowerCase()) {
      case 'rural':
        return const <MacroLocalOption>[
          MacroLocalOption(label: 'Rua', baseScore: 100, pinnedTop: true),
          MacroLocalOption(label: 'Área externa', baseScore: 80),
        ];
      case 'comercial':
      case 'industrial':
      case 'urbano':
      default:
        return const <MacroLocalOption>[
          MacroLocalOption(label: 'Rua', baseScore: 100, pinnedTop: true),
          MacroLocalOption(label: 'Área externa', baseScore: 80),
          MacroLocalOption(label: 'Área interna', baseScore: 60),
        ];
    }
  }

  List<RankedMenuOption> _fallbackAmbientes(
    String propertyType,
    String macroLocal,
  ) {
    final key = propertyType.trim().toLowerCase();
    if (macroLocal == 'Rua') {
      switch (key) {
        case 'rural':
          return const <RankedMenuOption>[
            RankedMenuOption(
              label: 'Acesso principal',
              baseScore: 100,
              pinnedTop: true,
            ),
            RankedMenuOption(label: 'Entrada da propriedade', baseScore: 95),
            RankedMenuOption(
              label: 'Identificação / referência',
              baseScore: 90,
            ),
          ];
        case 'comercial':
          return const <RankedMenuOption>[
            RankedMenuOption(label: 'Fachada', baseScore: 100, pinnedTop: true),
            RankedMenuOption(label: 'Logradouro', baseScore: 95),
            RankedMenuOption(label: 'Acesso principal', baseScore: 92),
          ];
        case 'industrial':
          return const <RankedMenuOption>[
            RankedMenuOption(
              label: 'Acesso principal',
              baseScore: 100,
              pinnedTop: true,
            ),
            RankedMenuOption(label: 'Fachada / portaria', baseScore: 95),
            RankedMenuOption(label: 'Número / identificação', baseScore: 90),
          ];
        case 'urbano':
        default:
          return const <RankedMenuOption>[
            RankedMenuOption(label: 'Fachada', baseScore: 100, pinnedTop: true),
            RankedMenuOption(label: 'Logradouro', baseScore: 95),
            RankedMenuOption(label: 'Acesso ao imóvel', baseScore: 92),
            RankedMenuOption(label: 'Entorno', baseScore: 88),
          ];
      }
    }

    if (macroLocal == 'Área externa') {
      return const <RankedMenuOption>[
        RankedMenuOption(label: 'Garagem', baseScore: 90),
        RankedMenuOption(label: 'Quintal', baseScore: 88),
        RankedMenuOption(label: 'Jardim', baseScore: 84),
      ];
    }

    return const <RankedMenuOption>[
      RankedMenuOption(label: 'Sala', baseScore: 90),
      RankedMenuOption(label: 'Quarto', baseScore: 88),
      RankedMenuOption(label: 'Cozinha', baseScore: 84),
    ];
  }

  List<RankedMenuOption> _fallbackElementos(
    String propertyType,
    String macroLocal,
    String ambiente,
  ) {
    switch (ambiente) {
      case 'Fachada':
      case 'Fachada / portaria':
        return const <RankedMenuOption>[
          RankedMenuOption(
            label: 'Visão geral',
            baseScore: 100,
            pinnedTop: true,
          ),
          RankedMenuOption(label: 'Número', baseScore: 95),
          RankedMenuOption(label: 'Porta', baseScore: 82),
          RankedMenuOption(label: 'Portão', baseScore: 80),
          RankedMenuOption(label: 'Janela', baseScore: 74),
          RankedMenuOption(
            label: 'Outro elemento',
            baseScore: 1,
            pinnedBottom: true,
          ),
        ];
      case 'Logradouro':
        return const <RankedMenuOption>[
          RankedMenuOption(
            label: 'Visão geral',
            baseScore: 100,
            pinnedTop: true,
          ),
          RankedMenuOption(label: 'Calçada', baseScore: 90),
          RankedMenuOption(label: 'Rua / via', baseScore: 88),
          RankedMenuOption(label: 'Pavimentação', baseScore: 82),
          RankedMenuOption(
            label: 'Outro elemento',
            baseScore: 1,
            pinnedBottom: true,
          ),
        ];
      case 'Acesso ao imóvel':
      case 'Acesso principal':
        return const <RankedMenuOption>[
          RankedMenuOption(
            label: 'Visão geral',
            baseScore: 100,
            pinnedTop: true,
          ),
          RankedMenuOption(label: 'Portão', baseScore: 94),
          RankedMenuOption(label: 'Porta', baseScore: 90),
          RankedMenuOption(label: 'Interfone', baseScore: 84),
          RankedMenuOption(label: 'Número', baseScore: 80),
          RankedMenuOption(
            label: 'Outro elemento',
            baseScore: 1,
            pinnedBottom: true,
          ),
        ];
      case 'Entrada da propriedade':
        return const <RankedMenuOption>[
          RankedMenuOption(
            label: 'Visão geral',
            baseScore: 100,
            pinnedTop: true,
          ),
          RankedMenuOption(label: 'Porteira', baseScore: 94),
          RankedMenuOption(label: 'Cerca', baseScore: 88),
          RankedMenuOption(label: 'Estrada interna', baseScore: 82),
          RankedMenuOption(
            label: 'Outro elemento',
            baseScore: 1,
            pinnedBottom: true,
          ),
        ];
      case 'Identificação / referência':
      case 'Número / identificação':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Número', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Placa', baseScore: 96),
          RankedMenuOption(label: 'Marco de referência', baseScore: 84),
          RankedMenuOption(
            label: 'Outro elemento',
            baseScore: 1,
            pinnedBottom: true,
          ),
        ];
      case 'Entorno':
        return const <RankedMenuOption>[
          RankedMenuOption(
            label: 'Visão geral',
            baseScore: 100,
            pinnedTop: true,
          ),
          RankedMenuOption(label: 'Rua / via', baseScore: 90),
          RankedMenuOption(label: 'Vegetação', baseScore: 76),
          RankedMenuOption(
            label: 'Outro elemento',
            baseScore: 1,
            pinnedBottom: true,
          ),
        ];
      default:
        return const <RankedMenuOption>[
          RankedMenuOption(
            label: 'Visão geral',
            baseScore: 100,
            pinnedTop: true,
          ),
          RankedMenuOption(
            label: 'Outro elemento',
            baseScore: 1,
            pinnedBottom: true,
          ),
        ];
    }
  }

  List<RankedMenuOption> _fallbackMateriais(String elemento) {
    switch (elemento) {
      case 'Piso':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Cerâmico', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Porcelanato', baseScore: 95),
          RankedMenuOption(label: 'Madeira', baseScore: 88),
          RankedMenuOption(label: 'Concreto', baseScore: 82),
        ];
      case 'Parede':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Pintura', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Azulejo', baseScore: 92),
          RankedMenuOption(label: 'Concreto', baseScore: 84),
        ];
      case 'Teto':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Pintura', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Gesso', baseScore: 90),
          RankedMenuOption(label: 'Concreto', baseScore: 82),
        ];
      case 'Porta':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Madeira', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Metal', baseScore: 90),
          RankedMenuOption(label: 'Vidro', baseScore: 80),
        ];
      case 'Janela':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Vidro', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Alumínio', baseScore: 90),
          RankedMenuOption(label: 'Madeira', baseScore: 82),
        ];
      case 'Bancada':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Granito', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Mármore', baseScore: 92),
          RankedMenuOption(label: 'Concreto', baseScore: 84),
        ];
      case 'Louças e metais':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Cerâmica', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Metal', baseScore: 92),
        ];
      case 'Portão':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Metal', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Madeira', baseScore: 82),
        ];
      case 'Número':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Metal', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Pintura', baseScore: 88),
        ];
      case 'Calçada':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Concreto', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Cerâmico', baseScore: 82),
        ];
      case 'Rua / via':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Asfalto', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Concreto', baseScore: 84),
        ];
      case 'Acesso':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Metal', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Concreto', baseScore: 84),
        ];
      case 'Interfone':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Metal', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Plástico', baseScore: 82),
        ];
      case 'Cobertura':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Telha', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Concreto', baseScore: 82),
        ];
      case 'Guarda-corpo':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Metal', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Vidro', baseScore: 82),
        ];
      case 'Tanque':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Cerâmica', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Concreto', baseScore: 82),
        ];
      default:
        return const <RankedMenuOption>[];
    }
  }

  List<RankedMenuOption> _fallbackEstados() {
    return const <RankedMenuOption>[
      RankedMenuOption(label: 'Novo', baseScore: 100, pinnedTop: true),
      RankedMenuOption(label: 'Bom', baseScore: 90),
      RankedMenuOption(label: 'Regular', baseScore: 75),
      RankedMenuOption(label: 'Ruim', baseScore: 60),
      RankedMenuOption(label: 'Péssimo', baseScore: 45),
    ];
  }
}
