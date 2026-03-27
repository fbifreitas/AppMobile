import 'classification_audit_entry.dart';
import 'technical_pending_matrix.dart';

class InspectionTechnicalSummary {
  final String tipoImovel;
  final int totalSubtipos;
  final int subtiposComCobertura;
  final int totalFotos;
  final double completionPercent;
  final TechnicalPendingMatrix pendingMatrix;
  final List<ClassificationAuditEntry> audits;

  const InspectionTechnicalSummary({
    required this.tipoImovel,
    required this.totalSubtipos,
    required this.subtiposComCobertura,
    required this.totalFotos,
    required this.completionPercent,
    required this.pendingMatrix,
    required this.audits,
  });

  bool get requiresJustification =>
      pendingMatrix.totalAdvisory > 0 || audits.any((item) => item.hasIssues);

  bool canProceedWith(String justification) {
    if (pendingMatrix.hasBlocking) return false;
    if (requiresJustification) {
      return justification.trim().isNotEmpty;
    }
    return true;
  }
}
