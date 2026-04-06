import 'package:appmobile/services/inspection_menu_preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const store = InspectionMenuPreferencesStore.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads empty maps when prefs are empty', () async {
    final snapshot = await store.load(
      usageKey: 'usage',
      predictionKey: 'prediction',
    );

    expect(snapshot.usage, isEmpty);
    expect(snapshot.prediction, isEmpty);
  });

  test('persists and reloads usage and prediction payloads', () async {
    await store.persistUsage(
      usageKey: 'usage',
      usage: <String, dynamic>{
        'macro::Rua': <String, dynamic>{'count': 2},
      },
    );
    await store.persistPrediction(
      predictionKey: 'prediction',
      prediction: <String, dynamic>{
        'ctx::Rua': <String, dynamic>{'captures': 3},
      },
    );

    final snapshot = await store.load(
      usageKey: 'usage',
      predictionKey: 'prediction',
    );

    expect(snapshot.usage['macro::Rua'], <String, dynamic>{'count': 2});
    expect(
      snapshot.prediction['ctx::Rua'],
      <String, dynamic>{'captures': 3},
    );
  });
}
