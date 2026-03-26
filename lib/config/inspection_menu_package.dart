import 'dart:convert';

class FeatureFlagsConfig {
  final bool enablePredictionV3;
  final bool enableRecentSuggestionsV3;

  const FeatureFlagsConfig({
    required this.enablePredictionV3,
    required this.enableRecentSuggestionsV3,
  });

  factory FeatureFlagsConfig.fromJson(Map<String, dynamic> json) {
    return FeatureFlagsConfig(
      enablePredictionV3: json['enablePredictionV3'] as bool? ?? true,
      enableRecentSuggestionsV3: json['enableRecentSuggestionsV3'] as bool? ?? true,
    );
  }

  const FeatureFlagsConfig.fallback()
      : enablePredictionV3 = true,
        enableRecentSuggestionsV3 = true;
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

  const PredictionPolicyConfig({
    required this.enabled,
    required this.minContextCaptures,
    required this.recencyWindowDays,
    required this.autoSelectElemento,
    required this.autoSelectMaterial,
    required this.autoSelectEstado,
    required this.maxRecentSuggestions,
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
    );
  }

  const PredictionPolicyConfig.fallback()
      : enabled = true,
        minContextCaptures = 2,
        recencyWindowDays = 45,
        autoSelectElemento = true,
        autoSelectMaterial = true,
        autoSelectEstado = true,
        maxRecentSuggestions = 3;
}

class RankedMenuOption {
  final String label;
  final double baseScore;
  final bool pinnedTop;
  final bool pinnedBottom;
  final List<RankedMenuOption> elements;

  const RankedMenuOption({
    required this.label,
    required this.baseScore,
    this.pinnedTop = false,
    this.pinnedBottom = false,
    this.elements = const [],
  });

  factory RankedMenuOption.fromJson(Map<String, dynamic> json) {
    return RankedMenuOption(
      label: json['label'] as String,
      baseScore: (json['baseScore'] ?? 0).toDouble(),
      pinnedTop: json['pinnedTop'] as bool? ?? false,
      pinnedBottom: json['pinnedBottom'] as bool? ?? false,
      elements: (json['elements'] as List<dynamic>? ?? const [])
          .map((item) => RankedMenuOption.fromJson(Map<String, dynamic>.from(item as Map)))
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
      ambientes: (json['ambientes'] as List<dynamic>? ?? const [])
          .map((item) => RankedMenuOption.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

class PropertyTypeCameraConfig {
  final List<MacroLocalOption> macroLocals;

  const PropertyTypeCameraConfig({required this.macroLocals});

  factory PropertyTypeCameraConfig.fromJson(Map<String, dynamic> json) {
    return PropertyTypeCameraConfig(
      macroLocals: (json['macroLocals'] as List<dynamic>? ?? const [])
          .map((item) => MacroLocalOption.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

class InspectionMenuPackage {
  final int packageVersion;
  final FeatureFlagsConfig featureFlags;
  final RankingPolicyConfig rankingPolicy;
  final PredictionPolicyConfig predictionPolicy;
  final Map<String, List<String>> photoFieldOrder;
  final Map<String, PropertyTypeCameraConfig> propertyTypeConfigs;

  const InspectionMenuPackage({
    required this.packageVersion,
    required this.featureFlags,
    required this.rankingPolicy,
    required this.predictionPolicy,
    required this.photoFieldOrder,
    required this.propertyTypeConfigs,
  });

  factory InspectionMenuPackage.fromRawJson(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return InspectionMenuPackage.fromJson(json);
  }

  factory InspectionMenuPackage.fromJson(Map<String, dynamic> json) {
    final photoFieldOrderJson =
        Map<String, dynamic>.from((json['step2']?['photoFieldOrder'] ?? const {}) as Map);
    final propertyTypesJson = Map<String, dynamic>.from(
      (json['camera']?['propertyTypes'] ?? const {}) as Map,
    );

    return InspectionMenuPackage(
      packageVersion: json['meta']?['packageVersion'] ?? 1,
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
        (key, value) => MapEntry(key, List<String>.from(value as List<dynamic>)),
      ),
      propertyTypeConfigs: propertyTypesJson.map(
        (key, value) => MapEntry(
          key,
          PropertyTypeCameraConfig.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      ),
    );
  }

  factory InspectionMenuPackage.fallback() {
    return const InspectionMenuPackage(
      packageVersion: 3,
      featureFlags: FeatureFlagsConfig.fallback(),
      rankingPolicy: RankingPolicyConfig.fallback(),
      predictionPolicy: PredictionPolicyConfig.fallback(),
      photoFieldOrder: {
        'urbano': ['fachada', 'logradouro', 'acesso_imovel'],
        'rural': ['acesso_principal', 'entrada_propriedade', 'identificacao_area'],
        'comercial': ['fachada_comercial', 'logradouro_comercial', 'acesso_comercial'],
        'industrial': ['acesso_industrial', 'fachada_industrial', 'identificacao_industrial'],
      },
      propertyTypeConfigs: {},
    );
  }

  PropertyTypeCameraConfig? configFor(String propertyType) {
    final key = propertyType.trim().toLowerCase();
    return propertyTypeConfigs[key];
  }

  List<String> orderedPhotoFieldsFor(String propertyType) {
    final key = propertyType.trim().toLowerCase();
    return photoFieldOrder[key] ?? const [];
  }
}
