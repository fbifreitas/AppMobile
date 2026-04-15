import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/inspection_technical_summary.dart';
import '../services/inspection_classification_audit_trail_service.dart';

class InspectionTechnicalOverviewScreen extends StatelessWidget {
  final InspectionTechnicalSummary summary;

  const InspectionTechnicalOverviewScreen({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final narrative = const InspectionClassificationAuditTrailService()
        .buildNarrative(summary.audits);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.tr('Auditoria Técnica', 'Technical audit')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            strings.tr(
              'Auditoria de classificação',
              'Classification audit',
            ),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Text(narrative),
        ],
      ),
    );
  }
}
