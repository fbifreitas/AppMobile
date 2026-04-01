import 'package:flutter/material.dart';

import '../models/inspection_technical_summary.dart';

class InspectionTechnicalSummaryCard extends StatelessWidget {
  final InspectionTechnicalSummary summary;

  const InspectionTechnicalSummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = summary.pendingMatrix.hasBlocking ? Colors.orange : Colors.green;
    final completion = (summary.completionPercent * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESUMO TÉCNICO FINAL',
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
              _MiniStat(label: 'Tipo', value: summary.tipoImovel),
              _MiniStat(label: 'Fotos', value: '${summary.totalFotos}'),
              _MiniStat(label: 'Subtipos cobertos', value: '${summary.subtiposComCobertura}/${summary.totalSubtipos}'),
              _MiniStat(label: 'Conclusão técnica', value: '$completion%'),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: summary.completionPercent,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 10),
          Text(
            summary.pendingMatrix.hasBlocking
                ? 'Existem pendências técnicas bloqueantes para conclusão normativa.'
                : 'Não há bloqueios técnicos normativos ativos.',
            style: TextStyle(
              color: statusColor.shade700,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
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
