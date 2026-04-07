import '../models/classification_audit_entry.dart';

class InspectionClassificationAuditTrailService {
  const InspectionClassificationAuditTrailService();

  String buildNarrative(List<ClassificationAuditEntry> entries) {
    if (entries.isEmpty) {
      return 'Nenhuma evidência técnica classificada até o momento.';
    }

    final buffer = StringBuffer();
    for (final entry in entries) {
      buffer.writeln(
        '- ${entry.subtipo}: ${entry.fullyClassified}/${entry.totalFotos} foto(s) completas; '
        'faltando elemento ${entry.missingElemento}, material ${entry.missingMaterial}, estado ${entry.missingEstado}.',
      );
    }
    return buffer.toString().trim();
  }
}
