import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
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
    final strings = AppStrings.of(context);
    final sections =
        <_SectionData>[
          _SectionData(strings.tr('Check-in', 'Check-in'), matrix.checkin),
          _SectionData(strings.tr('Captura', 'Capture'), matrix.capture),
          _SectionData(strings.tr('Revisao', 'Review'), matrix.review),
          _SectionData(strings.tr('Finalizacao', 'Finalization'), matrix.finalization),
        ].where((item) => item.items.isNotEmpty).toList();

    if (sections.isEmpty) {
      return const SizedBox.shrink();
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
            strings.tr('Pendencias tecnicas da vistoria', 'Inspection technical pending items'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.tr(
              'Veja o que falta e use o atalho para ir direto ao ponto de ajuste.',
              'See what is missing and use the shortcut to go directly to the adjustment point.',
            ),
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
    final strings = AppStrings.of(context);
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
                        _friendlyDescription(context, item),
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (onOpenPending != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => onOpenPending!.call(item),
                          icon: const Icon(Icons.near_me_outlined, size: 16),
                          label: Text(strings.tr('Ir para pendencia', 'Go to pending item')),
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

String _friendlyDescription(BuildContext context, TechnicalRuleResult item) {
  final strings = AppStrings.of(context);
  switch (item.stage) {
    case TechnicalRuleStage.checkin:
      return strings.tr(
        'No check-in obrigatorio: ${item.description}',
        'In required check-in: ${item.description}',
      );
    case TechnicalRuleStage.capture:
      return strings.tr(
        'Nas fotos capturadas: ${item.description}',
        'In captured photos: ${item.description}',
      );
    case TechnicalRuleStage.review:
      return strings.tr(
        'Na revisao das fotos: ${item.description}',
        'In photo review: ${item.description}',
      );
    case TechnicalRuleStage.finalization:
      return strings.tr(
        'Na etapa de finalizacao: ${item.description}',
        'In the finalization step: ${item.description}',
      );
  }
}

class _SectionData {
  final String title;
  final List<TechnicalRuleResult> items;

  const _SectionData(this.title, this.items);
}
