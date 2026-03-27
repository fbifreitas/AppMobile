import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/field_operation_state.dart';
import '../widgets/field_sync_status_card.dart';

class FieldOperationsCenterScreen extends StatefulWidget {
  const FieldOperationsCenterScreen({super.key});

  @override
  State<FieldOperationsCenterScreen> createState() => _FieldOperationsCenterScreenState();
}

class _FieldOperationsCenterScreenState extends State<FieldOperationsCenterScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<FieldOperationState>().refreshQueue());
  }

  @override
  Widget build(BuildContext context) {
    final operationState = context.watch<FieldOperationState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Operação de campo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FieldSyncStatusCard(
            pendingCount: operationState.pendingCount,
            failedCount: operationState.failedCount,
            conflictCount: operationState.conflictCount,
            syncing: operationState.syncing,
            lastSyncAt: operationState.lastSyncAt,
            onSync: operationState.synchronizeNow,
          ),
          const SizedBox(height: 16),
          Text(
            'Fila de sincronização',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...operationState.queue.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.actionType, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Job: ${item.jobId}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Status: ${item.status.label}', style: const TextStyle(fontSize: 12)),
                  if (item.retryCount > 0)
                    Text('Tentativas: ${item.retryCount}', style: const TextStyle(fontSize: 12)),
                  if (item.errorMessage != null && item.errorMessage!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.errorMessage!,
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                      ),
                    ),
                  if (item.conflictMessage != null && item.conflictMessage!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.conflictMessage!,
                        style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
