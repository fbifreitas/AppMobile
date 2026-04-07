import '../models/classification_audit_entry.dart';
import '../models/technical_evidence_input.dart';

class InspectionClassificationAuditService {
  const InspectionClassificationAuditService();

  List<ClassificationAuditEntry> build(List<TechnicalEvidenceInput> evidences) {
    final grouped = <String, List<TechnicalEvidenceInput>>{};
    for (final evidence in evidences) {
      final key =
          evidence.targetItem.trim().isEmpty
              ? 'Sem subtipo'
              : evidence.targetItem.trim();
      grouped.putIfAbsent(key, () => <TechnicalEvidenceInput>[]).add(evidence);
    }

    final results = grouped.entries.map((entry) {
      final items = entry.value;
      return ClassificationAuditEntry(
        subtipo: entry.key,
        totalFotos: items.length,
        fullyClassified: items.where((item) => item.isFullyClassified).length,
        missingElemento: items.where((item) => !item.hasTargetQualifier).length,
        missingMaterial:
            items.where((item) => item.hasTargetQualifier && !item.hasMaterial).length,
        missingEstado:
            items.where((item) => item.hasTargetQualifier && !item.hasTargetCondition).length,
      );
    }).toList()
      ..sort((a, b) => a.subtipo.compareTo(b.subtipo));

    return results;
  }
}
