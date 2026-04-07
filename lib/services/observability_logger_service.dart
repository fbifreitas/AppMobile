import '../models/observability_log_entry.dart';
import 'observability_event_store_service.dart';

class ObservabilityLoggerService {
  final ObservabilityEventStoreService store;

  const ObservabilityLoggerService({
    this.store = const ObservabilityEventStoreService(),
  });

  Future<void> log({
    required String category,
    required String level,
    required String message,
    Map<String, String> metadata = const <String, String>{},
  }) async {
    final entry = ObservabilityLogEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}_$category',
      category: category,
      level: level,
      message: message,
      createdAt: DateTime.now(),
      metadata: metadata,
    );
    await store.add(entry);
  }

  Future<void> info(String category, String message, {Map<String, String> metadata = const <String, String>{}}) {
    return log(
      category: category,
      level: 'info',
      message: message,
      metadata: metadata,
    );
  }

  Future<void> warning(String category, String message, {Map<String, String> metadata = const <String, String>{}}) {
    return log(
      category: category,
      level: 'warning',
      message: message,
      metadata: metadata,
    );
  }

  Future<void> error(String category, String message, {Map<String, String> metadata = const <String, String>{}}) {
    return log(
      category: category,
      level: 'error',
      message: message,
      metadata: metadata,
    );
  }
}
