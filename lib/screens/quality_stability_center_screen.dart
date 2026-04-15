import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/quality_gate_service.dart';
import '../widgets/quality_gate_summary_card.dart';
import '../widgets/stability_check_card.dart';

class QualityStabilityCenterScreen extends StatelessWidget {
  const QualityStabilityCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final summary = const QualityGateService().build(
      checkinScreenAvailable: true,
      cameraScreenAvailable: true,
      reviewScreenAvailable: true,
      fieldOpsAvailable: true,
      assistiveCenterAvailable: true,
      pendingQueue: 0,
      failedQueue: 0,
      conflictQueue: 0,
      syncScreenAvailable: true,
      voiceServiceAvailable: true,
      commandBarAvailable: true,
      recentHistoryAvailable: true,
      rankingAvailable: true,
      technicalSummaryAvailable: true,
      pendingMatrixAvailable: true,
      justificationFlowAvailable: true,
      technicalBlockingCount: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.tr('Qualidade e estabilidade', 'Quality and stability')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          QualityGateSummaryCard(summary: summary),
          const SizedBox(height: 12),
          ...summary.checks.map((item) => StabilityCheckCard(item: item)),
        ],
      ),
    );
  }
}
