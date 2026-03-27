import '../models/field_operation_sync_status.dart';
import '../models/field_sync_queue_item.dart';
import 'field_operation_retry_service.dart';
import 'field_sync_queue_service.dart';

typedef FieldSyncExecutor = Future<FieldSyncExecutionResult> Function(
  FieldSyncQueueItem item,
);

class FieldSyncExecutionResult {
  final bool success;
  final bool conflict;
  final String? message;

  const FieldSyncExecutionResult.success() : success = true, conflict = false, message = null;

  const FieldSyncExecutionResult.failure([this.message])
      : success = false,
        conflict = false;

  const FieldSyncExecutionResult.conflict([this.message])
      : success = false,
        conflict = true;
}

class FieldOperationSyncEngine {
  final FieldSyncQueueService queueService;
  final FieldOperationRetryService retryService;
  final FieldSyncExecutor executor;

  const FieldOperationSyncEngine({
    required this.executor,
    this.queueService = const FieldSyncQueueService(),
    this.retryService = const FieldOperationRetryService(),
  });

  Future<List<FieldSyncQueueItem>> synchronizePending() async {
    final queue = await queueService.pendingItems();
    final processed = <FieldSyncQueueItem>[];

    for (final item in queue) {
      var current = item.copyWith(
        updatedAt: DateTime.now(),
        status: FieldOperationSyncStatus.syncing,
        clearErrorMessage: true,
      );
      await queueService.updateItem(current);

      final result = await executor(current);

      if (result.success) {
        current = current.copyWith(
          updatedAt: DateTime.now(),
          status: FieldOperationSyncStatus.synced,
          clearErrorMessage: true,
          clearConflictMessage: true,
        );
        await queueService.updateItem(current);
      } else if (result.conflict) {
        current = await retryService.markConflict(
          current,
          message: result.message ?? 'Conflito de sincronização detectado.',
        );
      } else {
        current = await retryService.markFailed(
          current,
          message: result.message ?? 'Falha ao sincronizar.',
        );
      }

      processed.add(current);
    }

    return processed;
  }
}
