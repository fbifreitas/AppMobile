import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

class FieldSyncStatusCard extends StatelessWidget {
  final int pendingCount;
  final int failedCount;
  final int conflictCount;
  final bool syncing;
  final DateTime? lastSyncAt;
  final VoidCallback? onSync;

  const FieldSyncStatusCard({
    super.key,
    required this.pendingCount,
    required this.failedCount,
    required this.conflictCount,
    required this.syncing,
    this.lastSyncAt,
    this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final lastSyncText = lastSyncAt == null
        ? strings.tr('Ainda nao sincronizado', 'Not synced yet')
        : strings.tr(
            'Ultima sincronizacao: ${lastSyncAt!.hour.toString().padLeft(2, '0')}:${lastSyncAt!.minute.toString().padLeft(2, '0')}',
            'Last sync: ${lastSyncAt!.hour.toString().padLeft(2, '0')}:${lastSyncAt!.minute.toString().padLeft(2, '0')}',
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.tr('Operacao de campo', 'Field operation'),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(lastSyncText, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(context, strings.tr('Pendentes', 'Pending'), pendingCount, Colors.blueGrey),
              _pill(context, strings.tr('Falhas', 'Failures'), failedCount, Colors.orange),
              _pill(context, strings.tr('Conflitos', 'Conflicts'), conflictCount, Colors.red),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: syncing ? null : onSync,
              icon: Icon(syncing ? Icons.sync : Icons.cloud_upload_outlined),
              label: Text(
                syncing
                    ? strings.tr('Sincronizando...', 'Syncing...')
                    : strings.tr('Sincronizar agora', 'Sync now'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String label, int count, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.shade50,
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color.shade800,
        ),
      ),
    );
  }
}
