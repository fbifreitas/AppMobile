import '../models/data_governance_issue.dart';
import '../models/data_governance_summary.dart';

class DataGovernanceAuditService {
  const DataGovernanceAuditService();

  DataGovernanceSummary build({
    required bool hasRetentionPolicies,
    required bool hasCleanupPlan,
    required bool hasSensitiveDataNotice,
    required bool hasLocalStorageControls,
    required bool hasResumeExpiry,
  }) {
    final issues = <DataGovernanceIssue>[
      DataGovernanceIssue(
        id: 'retention_policy',
        title: 'Política de retenção definida',
        description: hasRetentionPolicies
            ? 'A política de retenção local foi definida.'
            : 'Não há política de retenção definida para dados locais.',
        severity: DataGovernanceSeverity.blocking,
        resolved: hasRetentionPolicies,
      ),
      DataGovernanceIssue(
        id: 'cleanup_plan',
        title: 'Plano de limpeza local',
        description: hasCleanupPlan
            ? 'Existe plano de limpeza controlada de dados locais.'
            : 'Não há plano de limpeza controlada de dados locais.',
        severity: DataGovernanceSeverity.warning,
        resolved: hasCleanupPlan,
      ),
      DataGovernanceIssue(
        id: 'sensitive_notice',
        title: 'Tratamento de dados sensíveis',
        description: hasSensitiveDataNotice
            ? 'Os dados sensíveis estão classificados na governança.'
            : 'Os dados sensíveis ainda não estão formalmente classificados.',
        severity: DataGovernanceSeverity.warning,
        resolved: hasSensitiveDataNotice,
      ),
      DataGovernanceIssue(
        id: 'local_storage_controls',
        title: 'Controles de armazenamento local',
        description: hasLocalStorageControls
            ? 'Os dados locais possuem controles básicos de governança.'
            : 'Os controles de armazenamento local ainda não foram formalizados.',
        severity: DataGovernanceSeverity.blocking,
        resolved: hasLocalStorageControls,
      ),
      DataGovernanceIssue(
        id: 'resume_expiry',
        title: 'Expiração de retomada',
        description: hasResumeExpiry
            ? 'Estados de retomada possuem expiração prevista.'
            : 'Estados de retomada não possuem expiração formalizada.',
        severity: DataGovernanceSeverity.info,
        resolved: hasResumeExpiry,
      ),
    ];

    return DataGovernanceSummary(issues: issues);
  }
}
