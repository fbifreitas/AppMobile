import '../services/inspection_export_service.dart';
import '../services/inspection_sync_queue_service.dart';
import '../services/inspection_sync_service.dart';
import '../state/app_state.dart';

class InspectionFinalizeResult {
  const InspectionFinalizeResult({
    required this.completedLocallyOnly,
    required this.message,
    required this.shouldExitFlow,
  });

  final bool completedLocallyOnly;
  final String message;
  final bool shouldExitFlow;
}

class InspectionFinalizeUseCase {
  InspectionFinalizeUseCase({
    InspectionExportService? exportService,
    InspectionSyncService? syncService,
    InspectionSyncQueueService? syncQueueService,
  }) : exportService = exportService ?? InspectionExportService(),
       syncService = syncService ?? const InspectionSyncService(),
       syncQueueService = syncQueueService ?? const InspectionSyncQueueService();

  static final InspectionFinalizeUseCase instance =
      InspectionFinalizeUseCase();

  final InspectionExportService exportService;
  final InspectionSyncService syncService;
  final InspectionSyncQueueService syncQueueService;

  Future<InspectionFinalizeResult> execute({
    required AppState appState,
    required Map<String, dynamic> payload,
  }) async {
    InspectionSyncResult syncResult = const InspectionSyncResult(
      success: false,
      message: '',
    );
    bool hasSyncResult = false;
    int queuedCount = 0;
    InspectionSyncQueueFlushResult? flushResult;
    bool finalizedLocallyOnly = false;
    bool shouldExitFlow = false;

    try {
      await exportService.export(payload);
      syncResult = await syncService.syncFinalInspection(payload);
      hasSyncResult = true;

      if (syncResult.success) {
        appState.atualizarReferenciasExternasJobAtual(
          idExterno: syncResult.processId,
          protocoloExterno: syncResult.protocolId ?? syncResult.processNumber,
        );
        flushResult = await syncQueueService.flush(syncService: syncService);
        await appState.finalizarJob();
        shouldExitFlow = true;
      } else if (syncService.isConfigured &&
          _isRetryableSyncFailure(syncResult)) {
        queuedCount = await syncQueueService.enqueue(
          payload,
          lastError: syncResult.message,
        );
        finalizedLocallyOnly = true;
        await appState.marcarJobAguardandoSincronizacao();
        shouldExitFlow = true;
      } else {
        finalizedLocallyOnly = !syncService.isConfigured;
        if (finalizedLocallyOnly) {
          await appState.finalizarJob();
          shouldExitFlow = true;
        }
      }
    } catch (error) {
      finalizedLocallyOnly = false;
      syncResult = InspectionSyncResult(
        success: false,
        message: 'Failed to prepare final submission: $error',
      );
      hasSyncResult = true;
    }

    final syncSuffix =
        !hasSyncResult
            ? ''
            : (syncResult.success
                ? _buildSyncSuccessMessage(
                  syncResult: syncResult,
                  flushResult: flushResult,
                )
                : _buildSyncFailureMessage(
                  syncResult: syncResult,
                  queuedCount: queuedCount,
                ));

    return InspectionFinalizeResult(
      completedLocallyOnly: finalizedLocallyOnly,
      shouldExitFlow: shouldExitFlow,
      message:
          finalizedLocallyOnly
              ? 'Inspection saved on device.$syncSuffix'
              : (syncResult.success
                  ? 'Inspection finalized successfully.$syncSuffix'
                  : 'Unable to finalize inspection.$syncSuffix'),
    );
  }

  bool _isRetryableSyncFailure(InspectionSyncResult syncResult) {
    final statusCode = syncResult.statusCode;
    if (statusCode == null) {
      return true;
    }
    if (statusCode >= 500) {
      return true;
    }
    return statusCode == 408 || statusCode == 429;
  }

  String _buildSyncSuccessMessage({
    required InspectionSyncResult syncResult,
    InspectionSyncQueueFlushResult? flushResult,
  }) {
    if (flushResult == null || flushResult.sentCount == 0) {
      return ' Synchronized with the server.';
    }
    return ' Synchronized with the server and older pending items were sent.';
  }

  String _buildSyncFailureMessage({
    required InspectionSyncResult syncResult,
    required int queuedCount,
  }) {
    final parts = <String>[];
    final message = syncResult.message.trim();
    if (message.isNotEmpty) {
      parts.add(message);
    }
    if (queuedCount > 0) {
      parts.add(
        queuedCount == 1
            ? '1 pending item was queued for synchronization.'
            : '$queuedCount pending items were queued for synchronization.',
      );
    }
    if (parts.isEmpty) {
      return '';
    }
    return ' ${parts.join(' ')}';
  }
}
