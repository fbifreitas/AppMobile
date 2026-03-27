import 'package:flutter/material.dart';

import '../services/data_governance_audit_service.dart';
import '../services/data_retention_policy_service.dart';
import '../services/local_data_cleanup_service.dart';
import '../services/sensitive_data_registry_service.dart';
import '../widgets/data_governance_issue_list.dart';
import '../widgets/data_governance_summary_card.dart';

class DataGovernanceCenterScreen extends StatelessWidget {
  const DataGovernanceCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final summary = const DataGovernanceAuditService().build(
      hasRetentionPolicies: true,
      hasCleanupPlan: true,
      hasSensitiveDataNotice: true,
      hasLocalStorageControls: true,
      hasResumeExpiry: true,
    );

    final policies = const DataRetentionPolicyService().defaultPolicies();
    final cleanupPlan = const LocalDataCleanupService().buildCleanupPlan();
    final sensitiveItems = const SensitiveDataRegistryService().items();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Segurança, dados e governança'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DataGovernanceSummaryCard(summary: summary),
          const SizedBox(height: 12),
          DataGovernanceIssueList(items: summary.issues),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Políticas de retenção',
            lines: policies
                .map((item) => '${item.scope.name}: ${item.maxEntries} itens / ${item.maxAgeDays} dias')
                .toList(),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Plano de limpeza local',
            lines: cleanupPlan,
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Itens sensíveis mapeados',
            lines: sensitiveItems,
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
