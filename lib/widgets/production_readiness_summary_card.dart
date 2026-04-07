import 'package:flutter/material.dart';

import '../models/production_readiness_summary.dart';

class ProductionReadinessSummaryCard extends StatelessWidget {
  final ProductionReadinessSummary summary;

  const ProductionReadinessSummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final color = summary.readyForProduction ? Colors.green : Colors.orange;

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
            'Resumo de prontidão para produção',
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
              _Mini(label: 'Itens', value: '${summary.total}'),
              _Mini(label: 'Concluídos', value: '${summary.doneCount}'),
              _Mini(label: 'Pendentes', value: '${summary.pendingCount}'),
              _Mini(label: 'Bloqueios', value: '${summary.blockingCount}'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary.readyForProduction
                ? 'Sem bloqueios críticos de prontidão para produção.'
                : 'Existem bloqueios críticos antes da promoção para produção.',
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
