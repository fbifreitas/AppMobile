import 'package:flutter/foundation.dart';

import '../models/field_inspection_resume_state.dart';
import '../models/field_operation_sync_status.dart';
import '../models/field_sync_queue_item.dart';
import '../services/field_operation_resume_service.dart';
import '../services/field_operation_sync_engine.dart';
import '../services/field_sync_queue_service.dart';

class FieldOperationState extends ChangeNotifier {
  FieldOperationState({
    required this.syncEngine,
    this.queueService = const FieldSyncQueueService(),
    this.resumeService = const FieldOperationResumeService(),
  });

  factory FieldOperationState.demo() {
    return FieldOperationState(
      syncEngine: const FieldOperationSyncEngine(
        executor: _demoExecutor,
      ),
    );
  }

  final FieldSyncQueueService queueService;
  final FieldOperationResumeService resumeService;
  final FieldOperationSyncEngine syncEngine;

  List<FieldSyncQueueItem> queue = const [];
  bool syncing = false;
  DateTime? lastSyncAt;

  static Future<FieldSyncExecutionResult> _demoExecutor(
    FieldSyncQueueItem item,
  ) async {
    return const FieldSyncExecutionResult.success();
  }

  Future<void> refreshQueue() async {
    queue = await queueService.loadQueue();
    notifyListeners();
  }

  Future<void> enqueueAction({
    required String id,
    required String jobId,
    required String actionType,
    required Map<String, dynamic> payload,
  }) async {
    await queueService.enqueue(
      id: id,
      jobId: jobId,
      actionType: actionType,
      payload: payload,
    );
    await refreshQueue();
  }

  Future<void> synchronizeNow() async {
    syncing = true;
    notifyListeners();

    try {
      await syncEngine.synchronizePending();
      lastSyncAt = DateTime.now();
      await refreshQueue();
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<void> saveResumeState(FieldInspectionResumeState state) async {
    await resumeService.saveState(state);
  }

  Future<FieldInspectionResumeState?> loadResumeState(String jobId) {
    return resumeService.loadState(jobId);
  }

  int get pendingCount =>
      queue.where((item) => item.status.isPending).length;

  int get failedCount =>
      queue.where((item) => item.status == FieldOperationSyncStatus.failed).length;

  int get conflictCount =>
      queue.where((item) => item.status == FieldOperationSyncStatus.conflict).length;
}
