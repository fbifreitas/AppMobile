import 'package:flutter/material.dart';

import '../models/observability_log_entry.dart';

class ObservabilityLogList extends StatelessWidget {
  final List<ObservabilityLogEntry> items;

  const ObservabilityLogList({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
        ),
        child: const Text('Nenhum log registrado até o momento.'),
      );
    }

    return Column(
      children: items.map((item) {
        final color = item.level == 'error'
            ? Colors.orange
            : item.level == 'warning'
                ? Colors.blueGrey
                : Colors.green;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.20)),
            color: color.withValues(alpha: 0.05),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    item.level == 'error'
                        ? Icons.error_outline
                        : item.level == 'warning'
                            ? Icons.warning_amber_rounded
                            : Icons.info_outline,
                    size: 18,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.category.toUpperCase()} • ${item.level}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(item.message, style: const TextStyle(fontSize: 12)),
              if (item.metadata.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.metadata.entries.map((entry) {
                    return Chip(
                      label: Text('${entry.key}: ${entry.value}'),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
