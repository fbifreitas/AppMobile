import '../config/inspection_menu_package.dart';
import '../models/inspection_menu_intelligence_models.dart';

class InspectionMenuIntelligenceService {
  InspectionMenuIntelligenceService._();

  static final InspectionMenuIntelligenceService instance =
      InspectionMenuIntelligenceService._();

  String? getSuggestedMacroLocal({
    required FeatureFlagsConfig featureFlags,
    required PredictionPolicyConfig predictionPolicy,
    required Map<String, dynamic> usage,
    required String propertyType,
    List<String> availableMacroLocals = const [],
  }) {
    if (!featureFlags.enableContextBootstrapV4) {
      return null;
    }

    return _topConfirmedValue(
      usage: usage,
      scope: 'camera_confirmed.${propertyType.toLowerCase()}.macro',
      allowed: availableMacroLocals,
      minCount: predictionPolicy.minContextSuggestionCaptures,
    );
  }

  String? getSuggestedAmbiente({
    required FeatureFlagsConfig featureFlags,
    required PredictionPolicyConfig predictionPolicy,
    required Map<String, dynamic> usage,
    required String propertyType,
    required String macroLocal,
    List<String> availableAmbientes = const [],
  }) {
    if (!featureFlags.enableContextBootstrapV4) {
      return null;
    }

    return _topConfirmedValue(
      usage: usage,
      scope:
          'camera_confirmed.${propertyType.toLowerCase()}.$macroLocal.ambiente',
      allowed: availableAmbientes,
      minCount: predictionPolicy.minContextSuggestionCaptures,
    );
  }

  List<String> getRecentAmbienteSuggestions({
    required FeatureFlagsConfig featureFlags,
    required PredictionPolicyConfig predictionPolicy,
    required Map<String, dynamic> usage,
    required String propertyType,
    required String macroLocal,
    List<String> availableAmbientes = const [],
  }) {
    if (!featureFlags.enableRecentAmbienteSuggestionsV4) {
      return const <String>[];
    }

    return _topConfirmedValues(
      usage: usage,
      scope:
          'camera_confirmed.${propertyType.toLowerCase()}.$macroLocal.ambiente',
      allowed: availableAmbientes,
      limit: predictionPolicy.maxRecentAmbienteSuggestions,
    );
  }

  SuggestedCameraContext? getSuggestedContext({
    required FeatureFlagsConfig featureFlags,
    required PredictionPolicyConfig predictionPolicy,
    required Map<String, dynamic> usage,
    required String propertyType,
    List<String> availableMacroLocals = const [],
    String? macroLocal,
    List<String> availableAmbientes = const [],
  }) {
    String? resolvedMacro = macroLocal;
    var confidenceSignals = 0;

    if (resolvedMacro == null || resolvedMacro.trim().isEmpty) {
      resolvedMacro = getSuggestedMacroLocal(
        featureFlags: featureFlags,
        predictionPolicy: predictionPolicy,
        usage: usage,
        propertyType: propertyType,
        availableMacroLocals: availableMacroLocals,
      );
      if (resolvedMacro != null) {
        confidenceSignals += 1;
      }
    }

    String? ambiente;
    if (resolvedMacro != null && resolvedMacro.trim().isNotEmpty) {
      ambiente = getSuggestedAmbiente(
        featureFlags: featureFlags,
        predictionPolicy: predictionPolicy,
        usage: usage,
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

  PredictedSelection? getPrediction({
    required FeatureFlagsConfig featureFlags,
    required PredictionPolicyConfig predictionPolicy,
    required Map<String, dynamic> prediction,
    required String propertyType,
    String? macroLocal,
    required String ambiente,
    List<String> availableElementos = const [],
    List<String> availableMateriais = const [],
    List<String> availableEstados = const [],
  }) {
    if (!featureFlags.enablePredictionV3 || !predictionPolicy.enabled) {
      return null;
    }

    final entry = _predictionEntry(
      prediction,
      _predictionContextKey(
        propertyType: propertyType,
        macroLocal: macroLocal,
        ambiente: ambiente,
      ),
    );
    if (entry == null) return null;

    final captures = (entry['captures'] as num?)?.toInt() ?? 0;
    if (captures < predictionPolicy.minContextCaptures) return null;

    final lastUsedAt = _parseDate(entry['lastUsedAt']);
    if (lastUsedAt != null) {
      final days = DateTime.now().difference(lastUsedAt).inDays;
      if (days > predictionPolicy.recencyWindowDays) return null;
    }

    final elemento =
        predictionPolicy.autoSelectElemento
            ? _pickBest(
              _intMap(entry['elementos']),
              allowed: availableElementos,
            )
            : null;
    final material =
        predictionPolicy.autoSelectMaterial
            ? _pickBest(
              _intMap(entry['materiais']),
              allowed: availableMateriais,
            )
            : null;
    final estado =
        predictionPolicy.autoSelectEstado
            ? _pickBest(_intMap(entry['estados']), allowed: availableEstados)
            : null;

    final value = PredictedSelection(
      elemento: elemento,
      material: material,
      estado: estado,
      captures: captures,
    );
    return value.hasAnyValue ? value : null;
  }

  List<String> getRecentElementSuggestions({
    required FeatureFlagsConfig featureFlags,
    required PredictionPolicyConfig predictionPolicy,
    required Map<String, dynamic> prediction,
    required String propertyType,
    String? macroLocal,
    required String ambiente,
    List<String> availableElementos = const [],
  }) {
    if (!featureFlags.enableRecentSuggestionsV3) {
      return const <String>[];
    }

    final entry = _predictionEntry(
      prediction,
      _predictionContextKey(
        propertyType: propertyType,
        macroLocal: macroLocal,
        ambiente: ambiente,
      ),
    );
    if (entry == null) return const <String>[];

    final sorted = _intMap(entry['elementos']).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final allowedSet = availableElementos.toSet();
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

  String predictionContextKey({
    required String propertyType,
    String? macroLocal,
    required String ambiente,
  }) => _predictionContextKey(
    propertyType: propertyType,
    macroLocal: macroLocal,
    ambiente: ambiente,
  );

  void registerConfirmedUsage({
    required Map<String, dynamic> usage,
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
        usage: usage,
        scope: 'camera_confirmed.$normalizedType.macro',
        value: macroLocal,
      );
      _incrementUsage(
        usage: usage,
        scope: 'camera_confirmed.$normalizedType.$macroLocal.ambiente',
        value: ambiente,
      );
    }

    if (elemento != null &&
        elemento.trim().isNotEmpty &&
        macroLocal != null &&
        macroLocal.trim().isNotEmpty) {
      _incrementUsage(
        usage: usage,
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
        usage: usage,
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
        usage: usage,
        scope:
            'camera_confirmed.$normalizedType.$macroLocal.$ambiente.$elemento.estado',
        value: estado,
      );
    }
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static Map<String, int> _intMap(Object? raw) {
    final map = Map<String, dynamic>.from(raw as Map? ?? const {});
    return map.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  static Map<String, dynamic>? _predictionEntry(
    Map<String, dynamic> prediction,
    String key,
  ) {
    final raw = prediction[key];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  static String _usageCompoundKey(String scope, String value) => '$scope::$value';

  static String _predictionContextKey({
    required String propertyType,
    String? macroLocal,
    required String ambiente,
  }) {
    final normalizedType = propertyType.trim().toLowerCase();
    final normalizedMacro = (macroLocal ?? '').trim().toLowerCase();
    final normalizedAmbiente = ambiente.trim().toLowerCase();
    return 'prediction::$normalizedType::$normalizedMacro::$normalizedAmbiente';
  }

  static String? _pickBest(
    Map<String, int> counts, {
    List<String> allowed = const [],
  }) {
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

  static void _incrementUsage({
    required Map<String, dynamic> usage,
    required String scope,
    required String value,
  }) {
    final key = _usageCompoundKey(scope, value);
    final entry = Map<String, dynamic>.from(
      usage[key] as Map? ?? const <String, dynamic>{},
    );
    entry['count'] = ((entry['count'] as num?)?.toInt() ?? 0) + 1;
    entry['lastUsedAt'] = DateTime.now().toIso8601String();
    usage[key] = entry;
  }

  static String? _topConfirmedValue({
    required Map<String, dynamic> usage,
    required String scope,
    List<String> allowed = const [],
    required int minCount,
  }) {
    final values = _topConfirmedValues(
      usage: usage,
      scope: scope,
      allowed: allowed,
      limit: 1,
    );
    if (values.isEmpty) return null;

    final entry = Map<String, dynamic>.from(
      usage[_usageCompoundKey(scope, values.first)] as Map? ??
          const <String, dynamic>{},
    );
    if (((entry['count'] as num?)?.toInt() ?? 0) < minCount) {
      return null;
    }
    return values.first;
  }

  static List<String> _topConfirmedValues({
    required Map<String, dynamic> usage,
    required String scope,
    List<String> allowed = const [],
    required int limit,
  }) {
    final prefix = '$scope::';
    final allowedSet = allowed.toSet();
    final entries =
        usage.entries.where((entry) => entry.key.startsWith(prefix)).where((
          entry,
        ) {
          if (allowedSet.isEmpty) return true;
          final value = entry.key.substring(prefix.length);
          return allowedSet.contains(value);
        }).toList()
          ..sort((a, b) {
            final aMap = Map<String, dynamic>.from(a.value as Map);
            final bMap = Map<String, dynamic>.from(b.value as Map);
            final countCompare = ((bMap['count'] as num?)?.toInt() ?? 0)
                .compareTo((aMap['count'] as num?)?.toInt() ?? 0);
            if (countCompare != 0) return countCompare;
            final aDate = _parseDate(aMap['lastUsedAt']) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = _parseDate(bMap['lastUsedAt']) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

    return entries
        .take(limit)
        .map((entry) => entry.key.substring(prefix.length))
        .toList();
  }
}
