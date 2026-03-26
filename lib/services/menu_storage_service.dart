import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/menu_usage_stat.dart';

class MenuStorageService {
  static const _usageKey = 'menu_usage_stats';

  Future<Map<String, MenuUsageStat>> loadUsageStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usageKey);
    if (raw == null || raw.isEmpty) return {};

    final Map<String, dynamic> decoded = jsonDecode(raw);
    return decoded.map(
      (key, value) => MapEntry(
        key,
        MenuUsageStat.fromJson(Map<String, dynamic>.from(value)),
      ),
    );
  }

  Future<void> saveUsageStats(Map<String, MenuUsageStat> stats) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      stats.map((key, value) => MapEntry(key, value.toJson())),
    );
    await prefs.setString(_usageKey, encoded);
  }
}
