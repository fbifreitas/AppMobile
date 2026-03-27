import '../models/field_operation_sync_status.dart';
import '../models/field_sync_queue_item.dart';
import 'field_operation_local_store.dart';

class FieldSyncQueueService {
  static const _storageKey = 'field_sync_queue_v1';

  final FieldOperationLocalStore localStore;

  const FieldSyncQueueService({
    this.localStore = const FieldOperationLocalStore(),
  });

  Future<List<FieldSyncQueueItem>> loadQueue() async {
    final raw = await localStore.loadList(_storageKey);
    return raw.map(FieldSyncQueueItem.fromJson).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> saveQueue(List<FieldSyncQueueItem> items) async {
    await localStore.saveList(
      _storageKey,
      items.map((item) => item.toJson()).toList(),
    );
  }

  Future<FieldSyncQueueItem> enqueue({
    required String id,
    required String jobId,
    required String actionType,
    required Map<String, dynamic> payload,
  }) async {
    final queue = await loadQueue();
    final now = DateTime.now();
    final item = FieldSyncQueueItem(
      id: id,
      jobId: jobId,
      actionType: actionType,
      payload: payload,
      createdAt: now,
      updatedAt: now,
      status: FieldOperationSyncStatus.queued,
    );
    queue.add(item);
    await saveQueue(queue);
    return item;
  }

  Future<void> updateItem(FieldSyncQueueItem updated) async {
    final queue = await loadQueue();
    final index = queue.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    queue[index] = updated;
    await saveQueue(queue);
  }

  Future<void> removeItem(String id) async {
    final queue = await loadQueue();
    queue.removeWhere((item) => item.id == id);
    await saveQueue(queue);
  }

  Future<List<FieldSyncQueueItem>> pendingItems() async {
    final queue = await loadQueue();
    return queue.where((item) => item.status.isPending).toList();
  }

  Future<void> clearSyncedItems() async {
    final queue = await loadQueue();
    final filtered = queue.where((item) => item.status != FieldOperationSyncStatus.synced).toList();
    await saveQueue(filtered);
  }
}
