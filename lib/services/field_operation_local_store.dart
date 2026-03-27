import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FieldOperationLocalStore {
  const FieldOperationLocalStore();

  Future<List<Map<String, dynamic>>> loadList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(key) ?? const <String>[];
    return raw
        .map((item) {
          try {
            return Map<String, dynamic>.from(jsonDecode(item) as Map);
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> saveList(String key, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      key,
      items.map((item) => jsonEncode(item)).toList(),
    );
  }

  Future<Map<String, dynamic>?> loadMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMap(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
