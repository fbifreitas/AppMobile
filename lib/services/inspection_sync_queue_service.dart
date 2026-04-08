import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'integration_context_service.dart';
import 'inspection_sync_service.dart';

class InspectionSyncQueueFlushResult {
  final int attemptedCount;
  final int sentCount;
  final int failedCount;
  final int remainingCount;
  final List<InspectionSyncedReference> syncedReferences;

  const InspectionSyncQueueFlushResult({
    required this.attemptedCount,
    required this.sentCount,
    required this.failedCount,
    required this.remainingCount,
    this.syncedReferences = const <InspectionSyncedReference>[],
  });
}

class InspectionSyncedReference {
  final String jobId;
  final String? externalId;
  final String? protocolId;
  final String? processNumber;
  final String? backendStatus;
  final String? receivedAtIso;

  const InspectionSyncedReference({
    required this.jobId,
    this.externalId,
    this.protocolId,
    this.processNumber,
    this.backendStatus,
    this.receivedAtIso,
  });
}

class InspectionSyncQueueService {
  const InspectionSyncQueueService();

  static const String _queueKey = 'inspection_sync_queue_payloads_v1';
  static const IntegrationContextService _integrationContextService =
      IntegrationContextService();

  Future<int> enqueue(
    Map<String, dynamic> payload, {
    String? lastError,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await _loadEntries(prefs);
    final entryId = _buildEntryId(payload);
    final nowIso = DateTime.now().toIso8601String();

    final index = entries.indexWhere((entry) => entry.id == entryId);
    if (index >= 0) {
      final current = entries[index];
      entries[index] = current.copyWith(
        payload: payload,
        attempts: current.attempts + 1,
        lastError: lastError,
        updatedAtIso: nowIso,
      );
    } else {
      entries.add(
        _QueueEntry(
          id: entryId,
          payload: payload,
          attempts: 1,
          queuedAtIso: nowIso,
          updatedAtIso: nowIso,
          lastError: lastError,
        ),
      );
    }

    await _saveEntries(prefs, entries);
    return entries.length;
  }

  Future<int> pendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await _loadEntries(prefs);
    return entries.length;
  }

  Future<InspectionSyncQueueFlushResult> flush({
    InspectionSyncService syncService = const InspectionSyncService(),
    int maxItemsPerRun = 30,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await _loadEntries(prefs);

    if (entries.isEmpty) {
      return const InspectionSyncQueueFlushResult(
        attemptedCount: 0,
        sentCount: 0,
        failedCount: 0,
        remainingCount: 0,
      );
    }

    if (!syncService.isConfigured) {
      return InspectionSyncQueueFlushResult(
        attemptedCount: 0,
        sentCount: 0,
        failedCount: 0,
        remainingCount: entries.length,
      );
    }

    var attempted = 0;
    var sent = 0;
    var failed = 0;
    final syncedReferences = <InspectionSyncedReference>[];

    final nextEntries = List<_QueueEntry>.from(entries);
    final batch = entries.take(maxItemsPerRun).toList();

    for (final entry in batch) {
      attempted += 1;
      final result = await syncService.syncFinalInspection(entry.payload);
      final index = nextEntries.indexWhere((item) => item.id == entry.id);
      if (index < 0) continue;

      if (result.success) {
        sent += 1;
        syncedReferences.add(
          InspectionSyncedReference(
            jobId: '${entry.payload['job']?['id'] ?? ''}'.trim(),
            externalId: result.processId,
            protocolId: result.protocolId,
            processNumber: result.processNumber,
            backendStatus: result.backendStatus,
            receivedAtIso: result.receivedAtIso,
          ),
        );
        nextEntries.removeAt(index);
      } else {
        failed += 1;
        nextEntries[index] = nextEntries[index].copyWith(
          attempts: nextEntries[index].attempts + 1,
          lastError: result.message,
          updatedAtIso: DateTime.now().toIso8601String(),
        );
      }
    }

    await _saveEntries(prefs, nextEntries);

    return InspectionSyncQueueFlushResult(
      attemptedCount: attempted,
      sentCount: sent,
      failedCount: failed,
      remainingCount: nextEntries.length,
      syncedReferences: syncedReferences,
    );
  }

  Future<List<_QueueEntry>> _loadEntries(SharedPreferences prefs) async {
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.trim().isEmpty) return <_QueueEntry>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <_QueueEntry>[];
      return decoded
          .whereType<Map>()
          .map(
            (map) => _QueueEntry.fromMap(
              Map<String, dynamic>.from(map.map((key, value) => MapEntry('$key', value))),
            ),
          )
          .toList();
    } catch (_) {
      return <_QueueEntry>[];
    }
  }

  Future<void> _saveEntries(
    SharedPreferences prefs,
    List<_QueueEntry> entries,
  ) async {
    await prefs.setString(
      _queueKey,
      jsonEncode(entries.map((entry) => entry.toMap()).toList()),
    );
  }

  String _buildEntryId(Map<String, dynamic> payload) {
    return _integrationContextService.buildIdempotencyKey(payload);
  }
}

class _QueueEntry {
  final String id;
  final Map<String, dynamic> payload;
  final int attempts;
  final String queuedAtIso;
  final String updatedAtIso;
  final String? lastError;

  const _QueueEntry({
    required this.id,
    required this.payload,
    required this.attempts,
    required this.queuedAtIso,
    required this.updatedAtIso,
    this.lastError,
  });

  factory _QueueEntry.fromMap(Map<String, dynamic> map) {
    return _QueueEntry(
      id: '${map['id'] ?? ''}',
      payload: Map<String, dynamic>.from(
        ((map['payload'] as Map?) ?? const <String, dynamic>{})
            .map((key, value) => MapEntry('$key', value)),
      ),
      attempts: (map['attempts'] as num?)?.toInt() ?? 0,
      queuedAtIso: '${map['queuedAtIso'] ?? ''}',
      updatedAtIso: '${map['updatedAtIso'] ?? ''}',
      lastError: map['lastError'] as String?,
    );
  }

  _QueueEntry copyWith({
    Map<String, dynamic>? payload,
    int? attempts,
    String? queuedAtIso,
    String? updatedAtIso,
    String? lastError,
  }) {
    return _QueueEntry(
      id: id,
      payload: payload ?? this.payload,
      attempts: attempts ?? this.attempts,
      queuedAtIso: queuedAtIso ?? this.queuedAtIso,
      updatedAtIso: updatedAtIso ?? this.updatedAtIso,
      lastError: lastError,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'payload': payload,
      'attempts': attempts,
      'queuedAtIso': queuedAtIso,
      'updatedAtIso': updatedAtIso,
      'lastError': lastError,
    };
  }
}
