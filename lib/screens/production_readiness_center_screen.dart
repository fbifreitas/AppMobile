import 'package:flutter/material.dart';

import '../services/operational_output_service.dart';
import '../services/production_navigation_map_service.dart';
import '../services/production_readiness_service.dart';
import '../widgets/production_readiness_list.dart';
import '../widgets/production_readiness_summary_card.dart';

class ProductionReadinessCenterScreen extends StatelessWidget {
  const ProductionReadinessCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final summary = const ProductionReadinessService().build(
      mainNavigationReady: true,
      reviewFlowReady: true,
      technicalSummaryReady: true,
      fieldOpsReady: true,
      observabilityReady: true,
      governanceReady: true,
      assistiveReady: true,
    );

    final entries = const ProductionNavigationMapService().entries();
    final outputs = const OperationalOutputService().buildChecklist(
      hasReviewFlow: true,
      hasTechnicalSummary: true,
      hasObservabilityCenter: true,
      hasGovernanceCenter: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produção e saída operacional'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ProductionReadinessSummaryCard(summary: summary),
          const SizedBox(height: 12),
          ProductionReadinessList(items: summary.items),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Mapa de navegação de produção',
            lines: entries,
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Checklist de saída operacional',
            lines: outputs,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _SectionCard({
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(item, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
