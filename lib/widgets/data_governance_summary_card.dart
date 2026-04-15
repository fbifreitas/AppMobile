import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/data_governance_summary.dart';

class DataGovernanceSummaryCard extends StatelessWidget {
  final DataGovernanceSummary summary;

  const DataGovernanceSummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final color = summary.canProceed ? Colors.green : Colors.orange;

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
            strings.tr('Resumo de governanca local', 'Local governance summary'),
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
              _Mini(label: strings.tr('Bloqueios', 'Blocks'), value: '${summary.blocking}'),
              _Mini(label: strings.tr('Pendencias', 'Pending'), value: '${summary.unresolved}'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary.canProceed
                ? strings.tr(
                    'Sem bloqueios criticos de governanca local.',
                    'No critical local governance blockers.',
                  )
                : strings.tr(
                    'Existem bloqueios criticos de governanca local.',
                    'There are critical local governance blockers.',
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
