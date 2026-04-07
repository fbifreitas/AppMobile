import 'package:flutter/material.dart';

import '../services/code_audit_catalog_service.dart';
import '../services/operational_center_registry_service.dart';
import '../widgets/code_audit_issue_list.dart';
import '../widgets/code_audit_summary_card.dart';
import '../widgets/operational_center_list_card.dart';

class CleanCodeAuditCenterScreen extends StatelessWidget {
  const CleanCodeAuditCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final summary = const CodeAuditCatalogService().buildDefaultSummary();
    final centers = const OperationalCenterRegistryService().entries();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoria de clean code'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CodeAuditSummaryCard(summary: summary),
          const SizedBox(height: 12),
          CodeAuditIssueList(items: summary.issues),
          const SizedBox(height: 12),
          OperationalCenterListCard(items: centers),
        ],
      ),
    );
  }
}
