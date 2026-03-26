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

class InspectionMenuService {
  InspectionMenuService._();

  static final InspectionMenuService instance = InspectionMenuService._();

  static const String _assetPath = 'assets/config/menu_update_package_v1.json';
  static const String _usageKey = 'inspection_menu_usage_v2_1';

  InspectionMenuPackage? _package;
  Future<void>? _loading;
  Map<String, _UsageEntry> _usage = {};

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
    } catch (_) {
      _usage = {};
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _usageKey,
      jsonEncode(_usage.map((key, value) => MapEntry(key, value.toJson()))),
    );
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
