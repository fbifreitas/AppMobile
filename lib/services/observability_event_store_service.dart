import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/observability_log_entry.dart';

class ObservabilityEventStoreService {
  const ObservabilityEventStoreService();

  static const String _storageKey = 'observability_log_entries_v1';
  static const int _maxEntries = 300;

  Future<List<ObservabilityLogEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];

    return raw
        .map((item) {
          try {
            return ObservabilityLogEntry.fromJson(
              jsonDecode(item) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<ObservabilityLogEntry>()
        .toList();
  }

  Future<void> add(ObservabilityLogEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    final updated = <ObservabilityLogEntry>[entry, ...current];
    final trimmed = updated.take(_maxEntries).toList();

    await prefs.setStringList(
      _storageKey,
      trimmed.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
