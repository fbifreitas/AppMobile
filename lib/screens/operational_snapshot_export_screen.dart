import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/operational_snapshot_export_service.dart';
import '../widgets/operational_snapshot_card.dart';

class OperationalSnapshotExportScreen extends StatelessWidget {
  const OperationalSnapshotExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const OperationalSnapshotExportService().build(
      checkinReady: true,
      fieldOpsReady: true,
      assistiveReady: true,
      qualityReady: true,
      observabilityReady: true,
      governanceReady: true,
      productionReady: true,
      adminReady: true,
    );
    final snapshotText = const OperationalSnapshotExportService().buildPlainText(
      appName: 'App Mobile',
      items: items,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saída operacional'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OperationalSnapshotCard(items: items),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
            ),
            child: SelectableText(snapshotText),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: snapshotText));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Snapshot copiado para a área de transferência.')),
              );
            },
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('Copiar snapshot'),
          ),
        ],
      ),
    );
  }
}
