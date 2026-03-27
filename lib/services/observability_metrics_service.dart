import '../models/observability_log_entry.dart';
import '../models/observability_metric_snapshot.dart';
import 'observability_event_store_service.dart';

class ObservabilityMetricsService {
  final ObservabilityEventStoreService store;

  const ObservabilityMetricsService({
    this.store = const ObservabilityEventStoreService(),
  });

  Future<ObservabilityMetricSnapshot> buildSnapshot() async {
    final logs = await store.load();

    int countCategory(String category) {
      return logs.where((item) => item.category == category).length;
    }

    return ObservabilityMetricSnapshot(
      totalLogs: logs.length,
      errorLogs: logs.where((item) => item.level == 'error').length,
      warningLogs: logs.where((item) => item.level == 'warning').length,
      syncEvents: countCategory('sync'),
      voiceEvents: countCategory('voice'),
      technicalEvents: countCategory('technical'),
      assistiveEvents: countCategory('assistive'),
    );
  }

  Future<List<ObservabilityLogEntry>> recent({int limit = 30}) async {
    final logs = await store.load();
    return logs.take(limit).toList();
  }
}
