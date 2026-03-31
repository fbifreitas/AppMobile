import 'package:flutter/material.dart';

import '../models/technical_pending_matrix.dart';
import '../models/technical_rule_result.dart';

class TechnicalPendingMatrixCard extends StatelessWidget {
  final TechnicalPendingMatrix matrix;
  final ValueChanged<TechnicalRuleResult>? onOpenPending;

  const TechnicalPendingMatrixCard({
    super.key,
    required this.matrix,
    this.onOpenPending,
  });

  @override
  Widget build(BuildContext context) {
    final sections =
        <_SectionData>[
          _SectionData('Check-in', matrix.checkin),
          _SectionData('Captura', matrix.capture),
          _SectionData('Revisão', matrix.review),
          _SectionData('Finalização', matrix.finalization),
        ].where((item) => item.items.isNotEmpty).toList();

    if (sections.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
        ),
        child: const Text('Nenhuma pendência técnica identificada.'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pendências técnicas da vistoria',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Veja o que falta e use o atalho para ir direto ao ponto de ajuste.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          ...sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StageSection(
                section: section,
                onOpenPending: onOpenPending,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageSection extends StatelessWidget {
  final _SectionData section;
  final ValueChanged<TechnicalRuleResult>? onOpenPending;

  const _StageSection({required this.section, this.onOpenPending});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        ...section.items.map((item) {
          final color = item.isBlocking ? Colors.orange : Colors.blueGrey;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.28)),
              color: color.withValues(alpha: 0.06),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.isBlocking
                      ? Icons.report_problem_outlined
                      : Icons.info_outline,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _friendlyDescription(item),
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (onOpenPending != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => onOpenPending!.call(item),
                          icon: const Icon(Icons.near_me_outlined, size: 16),
                          label: const Text('Ir para pendência'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

String _friendlyDescription(TechnicalRuleResult item) {
  switch (item.stage) {
    case TechnicalRuleStage.checkin:
      return 'No check-in obrigatório: ${item.description}';
    case TechnicalRuleStage.capture:
      return 'Nas fotos capturadas: ${item.description}';
    case TechnicalRuleStage.review:
      return 'Na revisão das fotos: ${item.description}';
    case TechnicalRuleStage.finalization:
      return 'Na etapa de finalização: ${item.description}';
  }
}

class _SectionData {
  final String title;
  final List<TechnicalRuleResult> items;

  const _SectionData(this.title, this.items);
}
