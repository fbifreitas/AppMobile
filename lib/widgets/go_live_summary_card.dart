import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/go_live_summary.dart';

class GoLiveSummaryCard extends StatelessWidget {
  final GoLiveSummary summary;

  const GoLiveSummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final color = summary.ready ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.tr('Checklist final de go-live', 'Final go-live checklist'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Mini(label: strings.tr('Itens', 'Items'), value: '${summary.total}'),
              _Mini(label: strings.tr('Concluidos', 'Completed'), value: '${summary.doneCount}'),
              _Mini(label: strings.tr('Pendentes', 'Pending'), value: '${summary.pendingCount}'),
              _Mini(label: strings.tr('Bloqueios', 'Blocks'), value: '${summary.blockingCount}'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary.ready
                ? strings.tr(
                    'Sem bloqueios criticos para o go-live.',
                    'No critical blockers for go-live.',
                  )
                : strings.tr(
                    'Ainda existem bloqueios criticos antes do go-live.',
                    'There are still critical blockers before go-live.',
                  ),
            style: TextStyle(
              color: color.shade700,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;

  const _Mini({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 11,
            fontFamily: DefaultTextStyle.of(context).style.fontFamily,
          ),
          children: [
            TextSpan(
              text: '$value ',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            TextSpan(text: label),
          ],
        ),
      ),
    );
  }
}
