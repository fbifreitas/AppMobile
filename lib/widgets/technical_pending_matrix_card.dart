import 'package:flutter/material.dart';

import '../models/technical_pending_matrix.dart';
import '../models/technical_rule_result.dart';

class TechnicalPendingMatrixCard extends StatelessWidget {
  final TechnicalPendingMatrix matrix;

  const TechnicalPendingMatrixCard({
    super.key,
    required this.matrix,
  });

  @override
  Widget build(BuildContext context) {
    final sections = <_SectionData>[
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
        ),
        child: const Text('Nenhuma pendência técnica identificada.'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Matriz de pendências técnicas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 10),
          ...sections.map((section) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StageSection(section: section),
              )),
        ],
      ),
    );
  }
}

class _StageSection extends StatelessWidget {
  final _SectionData section;

  const _StageSection({
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
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
                  item.isBlocking ? Icons.report_problem_outlined : Icons.info_outline,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(item.description, style: const TextStyle(fontSize: 12)),
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

class _SectionData {
  final String title;
  final List<TechnicalRuleResult> items;

  const _SectionData(this.title, this.items);
}
