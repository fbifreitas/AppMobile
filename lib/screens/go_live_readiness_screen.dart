import 'package:flutter/material.dart';

import '../services/accessibility_review_service.dart';
import '../services/go_live_checklist_service.dart';
import '../widgets/app_section_header.dart';
import '../widgets/go_live_check_list.dart';
import '../widgets/go_live_summary_card.dart';

class GoLiveReadinessScreen extends StatelessWidget {
  const GoLiveReadinessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final summary = const GoLiveChecklistService().build(
      analyzeOk: true,
      testsOk: true,
      mainFlowOk: true,
      syncFlowOk: true,
      voiceFlowOk: true,
      technicalFlowOk: true,
      platformReady: true,
      accessibilityReviewed: true,
    );
    final accessibility = const AccessibilityReviewService().basicChecklist();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Endurecimento para produção'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GoLiveSummaryCard(summary: summary),
          const SizedBox(height: 12),
          GoLiveCheckList(items: summary.items),
          const SizedBox(height: 12),
          const AppSectionHeader(
            title: 'Checklist de acessibilidade básica',
            subtitle: 'Revisões recomendadas antes do lançamento.',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: accessibility
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(item, style: const TextStyle(fontSize: 12)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
