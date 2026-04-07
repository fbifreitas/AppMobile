import 'package:flutter/material.dart';

import '../models/observability_metric_snapshot.dart';

class ObservabilityStatusCard extends StatelessWidget {
  final ObservabilityMetricSnapshot snapshot;

  const ObservabilityStatusCard({
    super.key,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final color = snapshot.errorLogs > 0 ? Colors.orange : Colors.green;

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
            'Resumo de observabilidade',
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
              _Mini(label: 'Logs', value: '${snapshot.totalLogs}'),
              _Mini(label: 'Erros', value: '${snapshot.errorLogs}'),
              _Mini(label: 'Alertas', value: '${snapshot.warningLogs}'),
              _Mini(label: 'Sync', value: '${snapshot.syncEvents}'),
              _Mini(label: 'Voz', value: '${snapshot.voiceEvents}'),
              _Mini(label: 'Técnico', value: '${snapshot.technicalEvents}'),
              _Mini(label: 'IA', value: '${snapshot.assistiveEvents}'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            snapshot.errorLogs > 0
                ? 'Foram detectados erros recentes. Recomendado revisar os logs abaixo.'
                : 'Nenhum erro recente registrado.',
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
