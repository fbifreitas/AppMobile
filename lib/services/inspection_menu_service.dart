import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/checkin_step2_config.dart';
import '../config/inspection_menu_package.dart';

class _UsageEntry {
  int count;
  DateTime? lastUsedAt;

  _UsageEntry({
    required this.count,
    required this.lastUsedAt,
  });

  factory _UsageEntry.fromJson(Map<String, dynamic> json) {
    return _UsageEntry(
      count: json['count'] as int? ?? 0,
      lastUsedAt: json['lastUsedAt'] != null
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
      lastUsedAt: json['lastUsedAt'] != null
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

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      _package = InspectionMenuPackage.fromRawJson(raw);
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

    final predictionPolicy = _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback();
    final featureFlags = _package?.featureFlags ?? const FeatureFlagsConfig.fallback();
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

    await _persistPrediction();
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

    final predictionPolicy = _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback();
    final featureFlags = _package?.featureFlags ?? const FeatureFlagsConfig.fallback();
    if (!featureFlags.enablePredictionV3 || !predictionPolicy.enabled) {
      return null;
    }

    final entry = _prediction[_predictionContextKey(
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

    final elemento = predictionPolicy.autoSelectElemento
        ? _pickBest(entry.elementos, allowed: availableElementos)
        : null;
    final material = predictionPolicy.autoSelectMaterial
        ? _pickBest(entry.materiais, allowed: availableMateriais)
        : null;
    final estado = predictionPolicy.autoSelectEstado
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

    final predictionPolicy = _package?.predictionPolicy ?? const PredictionPolicyConfig.fallback();
    final featureFlags = _package?.featureFlags ?? const FeatureFlagsConfig.fallback();
    if (!featureFlags.enableRecentSuggestionsV3) {
      return const <String>[];
    }

    final entry = _prediction[_predictionContextKey(
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
    )];
    if (entry == null) return const <String>[];

    final allowedSet = availableElementos.toSet();
    final sorted = entry.elementos.entries.toList()
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
    final orderedIds = _package?.orderedPhotoFieldsFor(tipoImovel.name) ?? const <String>[];
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

  Future<List<String>> getMacroLocals({
    required String propertyType,
  }) async {
    await ensureLoaded();
    final config = _package?.configFor(propertyType);
    final options = config?.macroLocals ?? _fallbackMacroLocals(propertyType);
    return _rankOptions(
      options: options,
      scope: 'camera.${propertyType.toLowerCase()}.macro',
    ).map((item) => item.label).toList();
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

    final options = selectedMacro?.ambientes ?? _fallbackAmbientes(propertyType, macroLocal);

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

    final options = selectedAmbiente?.elements ??
        _fallbackElementos(propertyType, macroLocal, ambiente);

    return _rankOptions(
      options: options,
      scope: 'camera.${propertyType.toLowerCase()}.$macroLocal.$ambiente.elemento',
    ).map((item) => item.label).toList();
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

  double _score({
    required RankedMenuOption option,
    required String scope,
  }) {
    final policy = _package?.rankingPolicy ?? const RankingPolicyConfig.fallback();
    final editorial = option.baseScore * policy.editorialWeight;

    final entry = _usage[_usageCompoundKey(scope, option.label)];
    if (entry == null) {
      return editorial;
    }

    final usage = entry.count >= policy.minUsesToReorder
        ? entry.count * 10 * policy.localUsageWeight
        : 0.0;

    double recency = 0;
    if (entry.lastUsedAt != null) {
      final days = DateTime.now().difference(entry.lastUsedAt!).inDays;
      if (days <= policy.decayDays) {
        recency = ((policy.decayDays - days) / policy.decayDays) *
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

  String? _pickBest(Map<String, int> counts, {List<String> allowed = const []}) {
    if (counts.isEmpty) return null;
    final allowedSet = allowed.toSet();
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in entries) {
      if (allowedSet.isEmpty || allowedSet.contains(entry.key)) {
        return entry.key;
      }
    }
    return null;
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
      jsonEncode(_prediction.map((key, value) => MapEntry(key, value.toJson()))),
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

  List<RankedMenuOption> _fallbackAmbientes(String propertyType, String macroLocal) {
    final key = propertyType.trim().toLowerCase();
    if (macroLocal == 'Rua') {
      switch (key) {
        case 'rural':
          return const <RankedMenuOption>[
            RankedMenuOption(label: 'Acesso principal', baseScore: 100, pinnedTop: true),
            RankedMenuOption(label: 'Entrada da propriedade', baseScore: 95),
            RankedMenuOption(label: 'Identificação / referência', baseScore: 90),
          ];
        case 'comercial':
          return const <RankedMenuOption>[
            RankedMenuOption(label: 'Fachada', baseScore: 100, pinnedTop: true),
            RankedMenuOption(label: 'Logradouro', baseScore: 95),
            RankedMenuOption(label: 'Acesso principal', baseScore: 92),
          ];
        case 'industrial':
          return const <RankedMenuOption>[
            RankedMenuOption(label: 'Acesso principal', baseScore: 100, pinnedTop: true),
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
          RankedMenuOption(label: 'Visão geral', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Número', baseScore: 95),
          RankedMenuOption(label: 'Porta', baseScore: 82),
          RankedMenuOption(label: 'Portão', baseScore: 80),
          RankedMenuOption(label: 'Janela', baseScore: 74),
          RankedMenuOption(label: 'Outro elemento', baseScore: 1, pinnedBottom: true),
        ];
      case 'Logradouro':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Visão geral', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Calçada', baseScore: 90),
          RankedMenuOption(label: 'Rua / via', baseScore: 88),
          RankedMenuOption(label: 'Pavimentação', baseScore: 82),
          RankedMenuOption(label: 'Outro elemento', baseScore: 1, pinnedBottom: true),
        ];
      case 'Acesso ao imóvel':
      case 'Acesso principal':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Visão geral', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Portão', baseScore: 94),
          RankedMenuOption(label: 'Porta', baseScore: 90),
          RankedMenuOption(label: 'Interfone', baseScore: 84),
          RankedMenuOption(label: 'Número', baseScore: 80),
          RankedMenuOption(label: 'Outro elemento', baseScore: 1, pinnedBottom: true),
        ];
      case 'Entrada da propriedade':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Visão geral', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Porteira', baseScore: 94),
          RankedMenuOption(label: 'Cerca', baseScore: 88),
          RankedMenuOption(label: 'Estrada interna', baseScore: 82),
          RankedMenuOption(label: 'Outro elemento', baseScore: 1, pinnedBottom: true),
        ];
      case 'Identificação / referência':
      case 'Número / identificação':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Número', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Placa', baseScore: 96),
          RankedMenuOption(label: 'Marco de referência', baseScore: 84),
          RankedMenuOption(label: 'Outro elemento', baseScore: 1, pinnedBottom: true),
        ];
      case 'Entorno':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Visão geral', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Rua / via', baseScore: 90),
          RankedMenuOption(label: 'Vegetação', baseScore: 76),
          RankedMenuOption(label: 'Outro elemento', baseScore: 1, pinnedBottom: true),
        ];
      default:
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Visão geral', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Outro elemento', baseScore: 1, pinnedBottom: true),
        ];
    }
  }
}
