import 'package:flutter/material.dart';

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
    final narrative = const InspectionClassificationAuditTrailService()
        .buildNarrative(summary.audits);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoria Técnica'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Auditoria De Classificação',
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
