import 'dart:convert';

class ConfigLevelDefinition {
  final String id;
  final String label;
  final bool required;
  final String? dependsOn;
  final List<String> options;
  final String? semanticKey;
  final List<String> aliases;
  final Map<String, String> labelsBySurface;

  const ConfigLevelDefinition({
    required this.id,
    required this.label,
    required this.required,
    required this.dependsOn,
    required this.options,
    this.semanticKey,
    this.aliases = const <String>[],
    this.labelsBySurface = const <String, String>{},
  });

  factory ConfigLevelDefinition.fromJson(Map<String, dynamic> json) {
    final id = '${json['id'] ?? ''}'.trim();
    final label = '${json['label'] ?? ''}'.trim();
    return ConfigLevelDefinition(
      id: id,
      label: label,
      required: json['required'] as bool? ?? true,
      dependsOn: _optionalText(json['dependsOn']),
      options: List<String>.from(json['options'] as List<dynamic>? ?? const []),
      semanticKey: _optionalText(
        json['semanticKey'] ?? json['semantic'] ?? json['fieldKey'],
      ),
      aliases: List<String>.from(json['aliases'] as List<dynamic>? ?? const []),
      labelsBySurface: _parseLabelsBySurface(json['labelsBySurface']),
    );
  }

  bool get isValid => id.isNotEmpty && label.isNotEmpty;
}

class CheckinStep1PackageConfig {
  final List<String> tipos;
  final Map<String, List<String>> subtiposPorTipo;
  final List<String> contextos;
  final List<ConfigLevelDefinition> levels;
  final Map<String, List<ConfigLevelDefinition>> levelsBySubtipo;

  const CheckinStep1PackageConfig({
    required this.tipos,
    required this.subtiposPorTipo,
    required this.contextos,
    required this.levels,
    required this.levelsBySubtipo,
  });

  factory CheckinStep1PackageConfig.fromJson(Map<String, dynamic> json) {
    final rawSubtipos = Map<String, dynamic>.from(
      (json['subtiposPorTipo'] ?? const {}) as Map,
    );

    return CheckinStep1PackageConfig(
      tipos: List<String>.from(json['tipos'] as List<dynamic>? ?? const []),
      subtiposPorTipo: rawSubtipos.map(
        (key, value) => MapEntry(
          key,
          List<String>.from(value as List<dynamic>? ?? const []),
        ),
      ),
      contextos: List<String>.from(
        json['contextos'] as List<dynamic>? ?? const [],
      ),
      levels: _parseLevelList(json['levels']),
      levelsBySubtipo: _parseTypedSubtypeLevels(json['levelsBySubtipo']),
    );
  }

  bool get isValid =>
      tipos.isNotEmpty && contextos.isNotEmpty && subtiposPorTipo.isNotEmpty;

  List<ConfigLevelDefinition> levelsFor({
    required String tipo,
    required String subtipo,
  }) {
    final key = _typedSubtypeKey(tipo: tipo, subtipo: subtipo);
    final bySubtype = levelsBySubtipo[key];
    if (bySubtype != null && bySubtype.isNotEmpty) {
      return bySubtype;
    }
    return levels;
  }
}

class FeatureFlagsConfig {
  final bool enablePredictionV3;
  final bool enableRecentSuggestionsV3;
  final bool enableContextBootstrapV4;
  final bool enableRecentAmbienteSuggestionsV4;

  const FeatureFlagsConfig({
    required this.enablePredictionV3,
    required this.enableRecentSuggestionsV3,
    required this.enableContextBootstrapV4,
    required this.enableRecentAmbienteSuggestionsV4,
  });

  factory FeatureFlagsConfig.fromJson(Map<String, dynamic> json) {
    return FeatureFlagsConfig(
      enablePredictionV3: json['enablePredictionV3'] as bool? ?? true,
      enableRecentSuggestionsV3:
          json['enableRecentSuggestionsV3'] as bool? ?? true,
      enableContextBootstrapV4:
          json['enableContextBootstrapV4'] as bool? ?? true,
      enableRecentAmbienteSuggestionsV4:
          json['enableRecentAmbienteSuggestionsV4'] as bool? ?? true,
    );
  }

  const FeatureFlagsConfig.fallback()
    : enablePredictionV3 = true,
      enableRecentSuggestionsV3 = true,
      enableContextBootstrapV4 = true,
      enableRecentAmbienteSuggestionsV4 = true;
}

class RankingPolicyConfig {
  final double editorialWeight;
  final double localUsageWeight;
  final double recencyWeight;
  final int minUsesToReorder;
  final int decayDays;

  const RankingPolicyConfig({
    required this.editorialWeight,
    required this.localUsageWeight,
    required this.recencyWeight,
    required this.minUsesToReorder,
    required this.decayDays,
  });

  factory RankingPolicyConfig.fromJson(Map<String, dynamic> json) {
    return RankingPolicyConfig(
      editorialWeight: (json['editorialWeight'] ?? 0.72).toDouble(),
      localUsageWeight: (json['localUsageWeight'] ?? 0.18).toDouble(),
      recencyWeight: (json['recencyWeight'] ?? 0.10).toDouble(),
      minUsesToReorder: json['minUsesToReorder'] ?? 3,
      decayDays: json['decayDays'] ?? 30,
    );
  }

  const RankingPolicyConfig.fallback()
    : editorialWeight = 0.72,
      localUsageWeight = 0.18,
      recencyWeight = 0.10,
      minUsesToReorder = 3,
      decayDays = 30;
}

class PredictionPolicyConfig {
  final bool enabled;
  final int minContextCaptures;
  final int recencyWindowDays;
  final bool autoSelectElemento;
  final bool autoSelectMaterial;
  final bool autoSelectEstado;
  final int maxRecentSuggestions;
  final int minContextSuggestionCaptures;
  final int maxRecentAmbienteSuggestions;

  const PredictionPolicyConfig({
    required this.enabled,
    required this.minContextCaptures,
    required this.recencyWindowDays,
    required this.autoSelectElemento,
    required this.autoSelectMaterial,
    required this.autoSelectEstado,
    required this.maxRecentSuggestions,
    required this.minContextSuggestionCaptures,
    required this.maxRecentAmbienteSuggestions,
  });

  factory PredictionPolicyConfig.fromJson(Map<String, dynamic> json) {
    return PredictionPolicyConfig(
      enabled: json['enabled'] as bool? ?? true,
      minContextCaptures: json['minContextCaptures'] ?? 2,
      recencyWindowDays: json['recencyWindowDays'] ?? 45,
      autoSelectElemento: json['autoSelectElemento'] as bool? ?? true,
      autoSelectMaterial: json['autoSelectMaterial'] as bool? ?? true,
      autoSelectEstado: json['autoSelectEstado'] as bool? ?? true,
      maxRecentSuggestions: json['maxRecentSuggestions'] ?? 3,
      minContextSuggestionCaptures: json['minContextSuggestionCaptures'] ?? 2,
      maxRecentAmbienteSuggestions: json['maxRecentAmbienteSuggestions'] ?? 3,
    );
  }

  const PredictionPolicyConfig.fallback()
    : enabled = true,
      minContextCaptures = 2,
      recencyWindowDays = 45,
      autoSelectElemento = true,
      autoSelectMaterial = true,
      autoSelectEstado = true,
      maxRecentSuggestions = 3,
      minContextSuggestionCaptures = 2,
      maxRecentAmbienteSuggestions = 3;
}

class RankedMenuOption {
  final String label;
  final double baseScore;
  final bool pinnedTop;
  final bool pinnedBottom;
  final List<RankedMenuOption> elements;
  final List<RankedMenuOption> materials;
  final List<RankedMenuOption> states;

  const RankedMenuOption({
    required this.label,
    required this.baseScore,
    this.pinnedTop = false,
    this.pinnedBottom = false,
    this.elements = const [],
    this.materials = const [],
    this.states = const [],
  });

  factory RankedMenuOption.fromJson(Map<String, dynamic> json) {
    return RankedMenuOption(
      label: json['label'] as String,
      baseScore: (json['baseScore'] ?? 0).toDouble(),
      pinnedTop: json['pinnedTop'] as bool? ?? false,
      pinnedBottom: json['pinnedBottom'] as bool? ?? false,
      elements:
          (json['elements'] as List<dynamic>? ?? const [])
              .map(
                (item) => RankedMenuOption.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
      materials:
          (json['materials'] as List<dynamic>? ?? const [])
              .map(
                (item) => RankedMenuOption.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
      states:
          (json['states'] as List<dynamic>? ?? const [])
              .map(
                (item) => RankedMenuOption.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
    );
  }
}

class MacroLocalOption extends RankedMenuOption {
  final List<RankedMenuOption> ambientes;

  const MacroLocalOption({
    required super.label,
    required super.baseScore,
    this.ambientes = const [],
    super.pinnedTop,
    super.pinnedBottom,
  });

  factory MacroLocalOption.fromJson(Map<String, dynamic> json) {
    return MacroLocalOption(
      label: json['label'] as String,
      baseScore: (json['baseScore'] ?? 0).toDouble(),
      pinnedTop: json['pinnedTop'] as bool? ?? false,
      pinnedBottom: json['pinnedBottom'] as bool? ?? false,
      ambientes:
          (json['ambientes'] as List<dynamic>? ?? const [])
              .map(
                (item) => RankedMenuOption.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
    );
  }
}

class PropertyTypeCameraConfig {
  final List<MacroLocalOption> macroLocals;
  final List<ConfigLevelDefinition> levels;
  final Map<String, List<ConfigLevelDefinition>> levelsBySubtipo;

  const PropertyTypeCameraConfig({
    required this.macroLocals,
    required this.levels,
    required this.levelsBySubtipo,
  });

  factory PropertyTypeCameraConfig.fromJson(Map<String, dynamic> json) {
    return PropertyTypeCameraConfig(
      macroLocals:
          (json['macroLocals'] as List<dynamic>? ?? const [])
              .map(
                (item) => MacroLocalOption.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
      levels: _parseLevelList(json['levels']),
      levelsBySubtipo: _parseSubtypeLevels(json['levelsBySubtipo']),
    );
  }

  List<ConfigLevelDefinition> levelsForSubtype(String subtipo) {
    final key = subtipo.trim().toLowerCase();
    final bySubtype = levelsBySubtipo[key];
    if (bySubtype != null && bySubtype.isNotEmpty) {
      return bySubtype;
    }
    return levels;
  }
}

class InspectionMenuPackage {
  final int packageVersion;
  final CheckinStep1PackageConfig? step1Config;
  final FeatureFlagsConfig featureFlags;
  final RankingPolicyConfig rankingPolicy;
  final PredictionPolicyConfig predictionPolicy;
  final Map<String, List<String>> photoFieldOrder;
  final Map<String, Map<String, dynamic>> step2ByType;
  final Map<String, PropertyTypeCameraConfig> propertyTypeConfigs;

  const InspectionMenuPackage({
    required this.packageVersion,
    required this.step1Config,
    required this.featureFlags,
    required this.rankingPolicy,
    required this.predictionPolicy,
    required this.photoFieldOrder,
    required this.step2ByType,
    required this.propertyTypeConfigs,
  });

  factory InspectionMenuPackage.fromRawJson(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return InspectionMenuPackage.fromJson(json);
  }

  factory InspectionMenuPackage.fromJson(Map<String, dynamic> json) {
    final step1Json =
        json['step1'] is Map
            ? Map<String, dynamic>.from((json['step1'] ?? const {}) as Map)
            : null;
    final step2Json =
        json['step2'] is Map
            ? Map<String, dynamic>.from((json['step2'] ?? const {}) as Map)
            : <String, dynamic>{};
    final photoFieldOrderJson = Map<String, dynamic>.from(
      (step2Json['photoFieldOrder'] ?? const {}) as Map,
    );
    final step2ByTypeSource =
        ((step2Json['byTipo'] as Map?)?.isNotEmpty ?? false)
            ? step2Json['byTipo']
            : ((step2Json['porTipo'] as Map?)?.isNotEmpty ?? false)
            ? step2Json['porTipo']
            : ((step2Json['tipos'] as Map?)?.isNotEmpty ?? false)
            ? step2Json['tipos']
            : const {};
    final step2ByTypeJson = Map<String, dynamic>.from(step2ByTypeSource as Map);
    final cameraJson = Map<String, dynamic>.from(
      (json['camera'] ?? const {}) as Map,
    );
    final propertyTypesSource =
        ((cameraJson['propertyTypes'] as Map?)?.isNotEmpty ?? false)
            ? cameraJson['propertyTypes']
            : ((cameraJson['byTipo'] as Map?)?.isNotEmpty ?? false)
            ? cameraJson['byTipo']
            : cameraJson['tipos'] ?? const {};
    final propertyTypesJson = Map<String, dynamic>.from(
      propertyTypesSource as Map,
    );

    return InspectionMenuPackage(
      packageVersion: json['meta']?['packageVersion'] ?? 1,
      step1Config:
          step1Json == null
              ? null
              : CheckinStep1PackageConfig.fromJson(step1Json),
      featureFlags: FeatureFlagsConfig.fromJson(
        Map<String, dynamic>.from(json['featureFlags'] ?? const {}),
      ),
      rankingPolicy: RankingPolicyConfig.fromJson(
        Map<String, dynamic>.from(json['rankingPolicy'] ?? const {}),
      ),
      predictionPolicy: PredictionPolicyConfig.fromJson(
        Map<String, dynamic>.from(json['predictionPolicy'] ?? const {}),
      ),
      photoFieldOrder: photoFieldOrderJson.map(
        (key, value) =>
            MapEntry(key, List<String>.from(value as List<dynamic>)),
      ),
      step2ByType: step2ByTypeJson.map(
        (key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)),
      ),
      propertyTypeConfigs: propertyTypesJson.map(
        (key, value) => MapEntry(
          key,
          PropertyTypeCameraConfig.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        ),
      ),
    );
  }

  factory InspectionMenuPackage.fallback() {
    return const InspectionMenuPackage(
      packageVersion: 3,
      step1Config: null,
      featureFlags: FeatureFlagsConfig.fallback(),
      rankingPolicy: RankingPolicyConfig.fallback(),
      predictionPolicy: PredictionPolicyConfig.fallback(),
      photoFieldOrder: {
        'urbano': ['fachada', 'logradouro', 'acesso_imovel'],
        'rural': [
          'acesso_principal',
          'entrada_propriedade',
          'identificacao_area',
        ],
        'comercial': [
          'fachada_comercial',
          'logradouro_comercial',
          'acesso_comercial',
        ],
        'industrial': [
          'acesso_industrial',
          'fachada_industrial',
          'identificacao_industrial',
        ],
      },
      step2ByType: {},
      propertyTypeConfigs: {},
    );
  }

  Map<String, dynamic>? step2For(String propertyType) {
    final key = propertyType.trim();
    return step2ByType[key] ??
        step2ByType[key.toLowerCase()] ??
        step2ByType[key.toUpperCase()];
  }

  PropertyTypeCameraConfig? configFor(String propertyType) {
    final key = propertyType.trim().toLowerCase();
    return propertyTypeConfigs[key];
  }

  List<String> orderedPhotoFieldsFor(String propertyType) {
    final key = propertyType.trim().toLowerCase();
    return photoFieldOrder[key] ?? const [];
  }

  List<ConfigLevelDefinition> cameraLevelsFor({
    required String propertyType,
    String? subtipo,
  }) {
    final config = configFor(propertyType);
    if (config == null) {
      return const [];
    }
    if (subtipo == null || subtipo.trim().isEmpty) {
      return config.levels;
    }
    return config.levelsForSubtype(subtipo);
  }
}

Map<String, List<ConfigLevelDefinition>> _parseSubtypeLevels(Object? value) {
  if (value is! Map) {
    return const {};
  }

  final source = Map<String, dynamic>.from(value);
  final result = <String, List<ConfigLevelDefinition>>{};

  source.forEach((subtipo, rawLevels) {
    final normalizedSubtipo = subtipo.toString().trim().toLowerCase();
    if (normalizedSubtipo.isEmpty) {
      return;
    }
    final levels = _parseLevelList(rawLevels);
    if (levels.isNotEmpty) {
      result[normalizedSubtipo] = levels;
    }
  });

  return result;
}

Map<String, List<ConfigLevelDefinition>> _parseTypedSubtypeLevels(
  Object? value,
) {
  if (value is! Map) {
    return const {};
  }

  final source = Map<String, dynamic>.from(value);
  final result = <String, List<ConfigLevelDefinition>>{};

  source.forEach((tipo, rawSubtipos) {
    if (rawSubtipos is! Map) {
      return;
    }

    final tipoText = tipo.toString().trim();
    if (tipoText.isEmpty) {
      return;
    }

    final subtipos = Map<String, dynamic>.from(rawSubtipos);
    subtipos.forEach((subtipo, rawLevels) {
      final subtipoText = subtipo.toString().trim();
      if (subtipoText.isEmpty) {
        return;
      }

      final levels = _parseLevelList(rawLevels);
      if (levels.isNotEmpty) {
        result[_typedSubtypeKey(tipo: tipoText, subtipo: subtipoText)] = levels;
      }
    });
  });

  return result;
}

List<ConfigLevelDefinition> _parseLevelList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map(
        (item) =>
            ConfigLevelDefinition.fromJson(Map<String, dynamic>.from(item)),
      )
      .where((level) => level.isValid)
      .toList();
}

String _typedSubtypeKey({required String tipo, required String subtipo}) {
  return '${tipo.trim().toLowerCase()}::${subtipo.trim().toLowerCase()}';
}

String? _optionalText(Object? value) {
  if (value == null) {
    return null;
  }
  final text = '$value'.trim();
  return text.isEmpty ? null : text;
}

Map<String, String> _parseLabelsBySurface(Object? value) {
  if (value is! Map) {
    return const <String, String>{};
  }

  final result = <String, String>{};
  final source = Map<String, dynamic>.from(value);
  source.forEach((key, rawValue) {
    final normalizedKey = key.trim();
    final normalizedValue = _optionalText(rawValue);
    if (normalizedKey.isEmpty || normalizedValue == null) {
      return;
    }
    result[normalizedKey] = normalizedValue;
  });
  return result;
}
