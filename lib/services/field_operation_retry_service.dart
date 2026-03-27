import '../models/field_operation_sync_status.dart';
import '../models/field_sync_queue_item.dart';
import 'field_sync_queue_service.dart';

class FieldOperationRetryService {
  final FieldSyncQueueService queueService;
  final int maxRetries;

  const FieldOperationRetryService({
    this.queueService = const FieldSyncQueueService(),
    this.maxRetries = 3,
  });

  Future<FieldSyncQueueItem> markFailed(
    FieldSyncQueueItem item, {
    required String message,
  }) async {
    final updated = item.copyWith(
      updatedAt: DateTime.now(),
      retryCount: item.retryCount + 1,
      status: item.retryCount + 1 >= maxRetries
          ? FieldOperationSyncStatus.conflict
          : FieldOperationSyncStatus.failed,
      errorMessage: message,
      clearConflictMessage: true,
    );
    await queueService.updateItem(updated);
    return updated;
  }

  Future<FieldSyncQueueItem> markRetryQueued(FieldSyncQueueItem item) async {
    final updated = item.copyWith(
      updatedAt: DateTime.now(),
      status: FieldOperationSyncStatus.queued,
      clearErrorMessage: true,
      clearConflictMessage: true,
    );
    await queueService.updateItem(updated);
    return updated;
  }

  Future<FieldSyncQueueItem> markConflict(
    FieldSyncQueueItem item, {
    required String message,
  }) async {
    final updated = item.copyWith(
      updatedAt: DateTime.now(),
      status: FieldOperationSyncStatus.conflict,
      conflictMessage: message,
    );
    await queueService.updateItem(updated);
    return updated;
  }
}
