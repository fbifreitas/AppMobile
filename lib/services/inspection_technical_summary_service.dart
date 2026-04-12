import '../models/inspection_technical_summary.dart';
import '../models/technical_check_requirement_input.dart';
import '../models/technical_evidence_input.dart';
import '../models/technical_pending_matrix.dart';
import 'inspection_classification_audit_service.dart';
import 'inspection_technical_rules_service.dart';

class InspectionTechnicalSummaryService {
  const InspectionTechnicalSummaryService();

  InspectionTechnicalSummary build({
    required String tipoImovel,
    required List<TechnicalEvidenceInput> evidences,
    required List<TechnicalCheckRequirementInput> requirements,
    required List<TechnicalCoverageRequirementInput> coverageRequirements,
  }) {
    final rulesService = const InspectionTechnicalRulesService();
    final auditService = const InspectionClassificationAuditService();

    final rules = rulesService.evaluate(
      tipoImovel: tipoImovel,
      evidences: evidences,
      requirements: requirements,
      coverageRequirements: coverageRequirements,
    );
    final audits = auditService.build(evidences);

    final totalSubtipos = audits.length;
    final subtiposComCobertura =
        audits.where((item) => item.totalFotos > 0).length;
    final fullyClassified =
        audits.fold<int>(0, (sum, item) => sum + item.fullyClassified);
    final totalFotos = evidences.length;

    final completionPercent = totalFotos == 0
        ? 0.0
        : (fullyClassified / totalFotos).clamp(0.0, 1.0);

    return InspectionTechnicalSummary(
      tipoImovel: tipoImovel,
      totalSubtipos: totalSubtipos,
      subtiposComCobertura: subtiposComCobertura,
      totalFotos: totalFotos,
      completionPercent: completionPercent,
      pendingMatrix: TechnicalPendingMatrix(items: rules),
      audits: audits,
    );
  }
}
