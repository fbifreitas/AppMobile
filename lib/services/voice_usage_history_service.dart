import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/voice_usage_entry.dart';

class VoiceUsageHistoryService {
  static const _storageKey = 'voice_usage_history_v1';
  static const _maxEntries = 50;

  Future<List<VoiceUsageEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    return raw
        .map((item) {
          try {
            return VoiceUsageEntry.fromJson(jsonDecode(item) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<VoiceUsageEntry>()
        .toList();
  }

  Future<void> add(VoiceUsageEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    final updated = <VoiceUsageEntry>[entry, ...current];
    final trimmed = updated.take(_maxEntries).toList();

    await prefs.setStringList(
      _storageKey,
      trimmed.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<List<VoiceUsageEntry>> recentByContext(String context, {int limit = 5}) async {
    final current = await load();
    return current.where((item) => item.context == context).take(limit).toList();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
