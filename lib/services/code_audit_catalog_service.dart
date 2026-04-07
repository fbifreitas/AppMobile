import '../models/code_audit_issue.dart';
import '../models/code_audit_summary.dart';

class CodeAuditCatalogService {
  const CodeAuditCatalogService();

  CodeAuditSummary buildDefaultSummary() {
    final issues = <CodeAuditIssue>[
      CodeAuditIssue(
        id: 'heavy_review_screen',
        title: 'Tela final concentrando muita responsabilidade',
        description: 'A revisão final ainda é candidata forte para extração de seções e helpers dedicados.',
        area: 'inspection_review_screen',
        severity: CodeAuditSeverity.blocking,
        plannedForRefactor: true,
      ),
      CodeAuditIssue(
        id: 'heavy_overlay_camera',
        title: 'Fluxo da câmera com acoplamento elevado',
        description: 'A tela da câmera ainda é candidata para extração de componentes menores e regras auxiliares.',
        area: 'overlay_camera_screen',
        severity: CodeAuditSeverity.blocking,
        plannedForRefactor: true,
      ),
      CodeAuditIssue(
        id: 'operational_centers_not_fully_integrated',
        title: 'Centrais operacionais ainda precisam navegação consolidada',
        description: 'As centrais adicionadas nos blocos finais precisam de um ponto de entrada operacional único.',
        area: 'navigation',
        severity: CodeAuditSeverity.warning,
        plannedForRefactor: true,
      ),
      CodeAuditIssue(
        id: 'catalogs_need_real_actions',
        title: 'Catálogos e checklists ainda precisam execução real',
        description: 'Algumas telas finais estão mais estruturais do que executoras e devem ser conectadas ao estado real.',
        area: 'admin_and_production',
        severity: CodeAuditSeverity.warning,
        plannedForRefactor: true,
      ),
      CodeAuditIssue(
        id: 'test_coverage_gap',
        title: 'Cobertura de testes ainda é limitada',
        description: 'A base de testes precisa crescer antes do go-live.',
        area: 'tests',
        severity: CodeAuditSeverity.warning,
        plannedForRefactor: true,
      ),
      CodeAuditIssue(
        id: 'platform_identity_cleanup',
        title: 'Identidade e permissões de release exigem revisão final',
        description: 'Nome do app, labels e consistência Android/iOS precisam endurecimento pré-lançamento.',
        area: 'platform_release',
        severity: CodeAuditSeverity.info,
        plannedForRefactor: true,
      ),
    ];

    return CodeAuditSummary(issues: issues);
  }
}
