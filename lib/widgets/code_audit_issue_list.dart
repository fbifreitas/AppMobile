import 'package:flutter/material.dart';

import '../models/code_audit_issue.dart';
import 'unified_section_card.dart';

class CodeAuditIssueList extends StatelessWidget {
  final List<CodeAuditIssue> items;

  const CodeAuditIssueList({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedSectionCard(
      title: 'Achados principais',
      subtitle: 'Base para os pacotes 10A, 10B, 11A e 11B.',
      child: Column(
        children: items.map((item) {
          final color = item.severity == CodeAuditSeverity.blocking
              ? Colors.orange
              : item.severity == CodeAuditSeverity.warning
                  ? Colors.blueGrey
                  : Colors.green;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.20)),
              color: color.withValues(alpha: 0.05),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.plannedForRefactor
                      ? Icons.rule_folder_outlined
                      : Icons.info_outline,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(item.description, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      Text('Área: ${item.area}', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
