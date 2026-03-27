import '../models/field_operation_cache_policy.dart';
import '../services/field_operation_local_store.dart';
import 'field_sync_queue_service.dart';

class FieldOperationCacheService {
  final FieldOperationCachePolicy cachePolicy;
  final FieldSyncQueueService queueService;
  final FieldOperationLocalStore localStore;

  const FieldOperationCacheService({
    this.cachePolicy = const FieldOperationCachePolicy(),
    this.queueService = const FieldSyncQueueService(),
    this.localStore = const FieldOperationLocalStore(),
  });

  Future<void> runControlledCleanup() async {
    final queue = await queueService.loadQueue();
    if (queue.length <= cachePolicy.maxQueueItems) {
      return;
    }

    final sorted = [...queue]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final trimmed = sorted.take(cachePolicy.maxQueueItems).toList();
    await queueService.saveQueue(trimmed);
  }
}
