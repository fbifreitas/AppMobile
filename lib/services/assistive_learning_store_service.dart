import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/assistive_learning_event.dart';

class AssistiveLearningStoreService {
  const AssistiveLearningStoreService();

  static const _storageKey = 'assistive_learning_events_v1';
  static const _maxEntries = 200;

  Future<List<AssistiveLearningEvent>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];

    return raw
        .map((item) {
          try {
            return AssistiveLearningEvent.fromJson(
              jsonDecode(item) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<AssistiveLearningEvent>()
        .toList();
  }

  Future<void> add(AssistiveLearningEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    final updated = <AssistiveLearningEvent>[event, ...current];
    final trimmed = updated.take(_maxEntries).toList();

    await prefs.setStringList(
      _storageKey,
      trimmed.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<List<AssistiveLearningEvent>> byContext(String context) async {
    final current = await load();
    return current.where((item) => item.context == context).toList();
  }

  Future<Map<String, int>> aggregate(String context, String key) async {
    final events = await byContext(context);
    final result = <String, int>{};

    for (final event in events.where((item) => item.key == key)) {
      result.update(event.value, (value) => value + event.weight, ifAbsent: () => event.weight);
    }

    return result;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
