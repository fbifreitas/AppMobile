import 'package:appmobile/services/inspection_sync_queue_service.dart';
import 'package:appmobile/services/inspection_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSyncService extends InspectionSyncService {
  _FakeSyncService({
    required this.configured,
    required this.resultsByJobId,
  });

  final bool configured;
  final Map<String, InspectionSyncResult> resultsByJobId;

  @override
  bool get isConfigured => configured;

  @override
  Future<InspectionSyncResult> syncFinalInspection(
    Map<String, dynamic> payload,
  ) async {
    final jobId = '${payload['job']?['id'] ?? ''}';
    return resultsByJobId[jobId] ??
        const InspectionSyncResult(success: true, message: 'ok');
  }
}

Map<String, dynamic> _payload({required String jobId, required String exportedAt}) {
  return {
    'job': {'id': jobId},
    'exportedAt': exportedAt,
    'review': {'capturas': []},
  };
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('enqueue adds new payload and updates pending count', () async {
    const service = InspectionSyncQueueService();

    final size = await service.enqueue(
      _payload(jobId: 'job-1', exportedAt: '2026-03-29T10:00:00.000Z'),
    );

    expect(size, 1);
    expect(await service.pendingCount(), 1);
  });

  test('enqueue deduplicates by job id + exportedAt', () async {
    const service = InspectionSyncQueueService();
    final payload = _payload(jobId: 'job-1', exportedAt: '2026-03-29T10:00:00.000Z');

    await service.enqueue(payload, lastError: 'erro 1');
    final size = await service.enqueue(payload, lastError: 'erro 2');

    expect(size, 1);
    expect(await service.pendingCount(), 1);
  });

  test('flush does nothing when sync is not configured', () async {
    const service = InspectionSyncQueueService();
    await service.enqueue(_payload(jobId: 'job-1', exportedAt: '2026-03-29T10:00:00.000Z'));

    final result = await service.flush(
      syncService: _FakeSyncService(configured: false, resultsByJobId: const {}),
    );

    expect(result.attemptedCount, 0);
    expect(result.sentCount, 0);
    expect(result.failedCount, 0);
    expect(result.remainingCount, 1);
    expect(await service.pendingCount(), 1);
  });

  test('flush removes successful entries and keeps failed ones', () async {
    const service = InspectionSyncQueueService();
    await service.enqueue(_payload(jobId: 'job-ok', exportedAt: '2026-03-29T10:00:00.000Z'));
    await service.enqueue(_payload(jobId: 'job-fail', exportedAt: '2026-03-29T10:01:00.000Z'));

    final result = await service.flush(
      syncService: _FakeSyncService(
        configured: true,
        resultsByJobId: const {
          'job-ok': InspectionSyncResult(success: true, message: 'ok', statusCode: 201),
          'job-fail': InspectionSyncResult(success: false, message: 'erro backend', statusCode: 500),
        },
      ),
    );

    expect(result.attemptedCount, 2);
    expect(result.sentCount, 1);
    expect(result.failedCount, 1);
    expect(result.remainingCount, 1);
    expect(result.syncedReferences, hasLength(1));
    expect(result.syncedReferences.first.jobId, 'job-ok');
    expect(await service.pendingCount(), 1);
  });

  test('flush returns reconciliable references from backend success payload', () async {
    const service = InspectionSyncQueueService();
    await service.enqueue(
      _payload(jobId: 'job-1', exportedAt: '2026-03-29T10:00:00.000Z'),
    );

    final result = await service.flush(
      syncService: _FakeSyncService(
        configured: true,
        resultsByJobId: const {
          'job-1': InspectionSyncResult(
            success: true,
            message: 'ok',
            statusCode: 200,
            processId: 'proc-1',
            protocolId: 'INS-2026-0001',
            processNumber: '190108',
            backendStatus: 'SUBMITTED',
            receivedAtIso: '2026-04-05T13:00:00Z',
          ),
        },
      ),
    );

    expect(result.syncedReferences, hasLength(1));
    expect(result.syncedReferences.first.jobId, 'job-1');
    expect(result.syncedReferences.first.externalId, 'proc-1');
    expect(result.syncedReferences.first.protocolId, 'INS-2026-0001');
    expect(result.syncedReferences.first.processNumber, '190108');
    expect(result.syncedReferences.first.backendStatus, 'SUBMITTED');
    expect(result.syncedReferences.first.receivedAtIso, '2026-04-05T13:00:00Z');
  });

  test('flush respects max items per run', () async {
    const service = InspectionSyncQueueService();
    await service.enqueue(_payload(jobId: 'job-1', exportedAt: '2026-03-29T10:00:00.000Z'));
    await service.enqueue(_payload(jobId: 'job-2', exportedAt: '2026-03-29T10:01:00.000Z'));

    final result = await service.flush(
      syncService: _FakeSyncService(configured: true, resultsByJobId: const {}),
      maxItemsPerRun: 1,
    );

    expect(result.attemptedCount, 1);
    expect(result.sentCount, 1);
    expect(result.failedCount, 0);
    expect(result.remainingCount, 1);
    expect(await service.pendingCount(), 1);
  });
}
