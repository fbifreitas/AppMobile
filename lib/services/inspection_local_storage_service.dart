import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/inspection_session_model.dart';

class InspectionLocalStorageService {
  static const _activeSessionKey = 'inspection_active_session_v1';
  static const _pendingSessionsKey = 'inspection_pending_sessions_v1';

  Future<void> saveActiveSession(InspectionSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _activeSessionKey,
      jsonEncode(session.toMap()),
    );
  }

  Future<InspectionSession?> loadActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeSessionKey);
    if (raw == null || raw.isEmpty) return null;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    return InspectionSession.fromMap(map);
  }

  Future<void> clearActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeSessionKey);
  }

  Future<void> queuePendingUpload(InspectionSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_pendingSessionsKey) ?? const <String>[];
    final list = List<String>.from(rawList);

    list.removeWhere((item) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      return decoded['id'] == session.id;
    });

    list.add(jsonEncode(session.toMap()));
    await prefs.setStringList(_pendingSessionsKey, list);
  }

  Future<List<InspectionSession>> loadPendingUploads() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_pendingSessionsKey) ?? const <String>[];

    return rawList.map((item) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      return InspectionSession.fromMap(map);
    }).toList();
  }

  Future<void> removePendingUpload(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_pendingSessionsKey) ?? const <String>[];
    final list = List<String>.from(rawList);

    list.removeWhere((item) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      return decoded['id'] == sessionId;
    });

    await prefs.setStringList(_pendingSessionsKey, list);
  }
}