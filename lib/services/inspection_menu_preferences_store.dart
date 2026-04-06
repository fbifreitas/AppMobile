import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class InspectionMenuPreferencesSnapshot {
  final Map<String, dynamic> usage;
  final Map<String, dynamic> prediction;

  const InspectionMenuPreferencesSnapshot({
    required this.usage,
    required this.prediction,
  });
}

class InspectionMenuPreferencesStore {
  const InspectionMenuPreferencesStore();

  static const InspectionMenuPreferencesStore instance =
      InspectionMenuPreferencesStore();

  Future<InspectionMenuPreferencesSnapshot> load({
    required String usageKey,
    required String predictionKey,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawUsage = prefs.getString(usageKey);
      final rawPrediction = prefs.getString(predictionKey);

      final usage =
          rawUsage != null && rawUsage.trim().isNotEmpty
              ? Map<String, dynamic>.from(
                jsonDecode(rawUsage) as Map<String, dynamic>,
              )
              : const <String, dynamic>{};

      final prediction =
          rawPrediction != null && rawPrediction.trim().isNotEmpty
              ? Map<String, dynamic>.from(
                jsonDecode(rawPrediction) as Map<String, dynamic>,
              )
              : const <String, dynamic>{};

      return InspectionMenuPreferencesSnapshot(
        usage: usage,
        prediction: prediction,
      );
    } catch (_) {
      return const InspectionMenuPreferencesSnapshot(
        usage: <String, dynamic>{},
        prediction: <String, dynamic>{},
      );
    }
  }

  Future<void> persistUsage({
    required String usageKey,
    required Map<String, dynamic> usage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(usageKey, jsonEncode(usage));
  }

  Future<void> persistPrediction({
    required String predictionKey,
    required Map<String, dynamic> prediction,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(predictionKey, jsonEncode(prediction));
  }
}
