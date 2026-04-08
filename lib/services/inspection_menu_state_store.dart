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

/// Manages in-memory usage and prediction state for the inspection menu.
///
/// Owns the mutable maps, serialization DTOs, and persistence coordination —
/// keeping [InspectionMenuService] focused on orchestration.
class InspectionMenuStateStore {
  InspectionMenuStateStore({
    InspectionMenuPreferencesStore preferencesStore =
        InspectionMenuPreferencesStore.instance,
  }) : _preferencesStore = preferencesStore;

  static final InspectionMenuStateStore instance = InspectionMenuStateStore();

  final InspectionMenuPreferencesStore _preferencesStore;

  Map<String, _UsageEntry> _usage = {};
  Map<String, _PredictionEntry> _prediction = {};

  Future<void> load({
    required String usageKey,
    required String predictionKey,
  }) async {
    try {
      final snapshot = await _preferencesStore.load(
        usageKey: usageKey,
        predictionKey: predictionKey,
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

  void reset() {
    _usage = {};
    _prediction = {};
  }

  void registerUsage({required String key}) {
    final entry = _usage.putIfAbsent(
      key,
      () => _UsageEntry(count: 0, lastUsedAt: null),
    );
    entry.count += 1;
    entry.lastUsedAt = DateTime.now();
  }

  void registerPrediction({
    required String key,
    String? elemento,
    String? material,
    String? estado,
  }) {
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
      entry.elementos.update(elemento, (v) => v + 1, ifAbsent: () => 1);
    }
    if (material != null && material.trim().isNotEmpty) {
      entry.materiais.update(material, (v) => v + 1, ifAbsent: () => 1);
    }
    if (estado != null && estado.trim().isNotEmpty) {
      entry.estados.update(estado, (v) => v + 1, ifAbsent: () => 1);
    }
  }

  Map<String, dynamic> usageSnapshot() =>
      _usage.map((key, value) => MapEntry(key, value.toJson()));

  Map<String, dynamic> predictionSnapshot() =>
      _prediction.map((key, value) => MapEntry(key, value.toJson()));

  void replaceUsageFromSnapshot(Map<String, dynamic> snapshot) {
    _usage = snapshot.map(
      (key, value) => MapEntry(
        key,
        _UsageEntry.fromJson(Map<String, dynamic>.from(value as Map)),
      ),
    );
  }

  Future<void> persistUsage(String usageKey) async {
    await _preferencesStore.persistUsage(
      usageKey: usageKey,
      usage: usageSnapshot(),
    );
  }

  Future<void> persistPrediction(String predictionKey) async {
    await _preferencesStore.persistPrediction(
      predictionKey: predictionKey,
      prediction: predictionSnapshot(),
    );
  }
}
