import '../models/production_readiness_item.dart';
import '../models/production_readiness_summary.dart';

class ProductionReadinessService {
  const ProductionReadinessService();

  ProductionReadinessSummary build({
    required bool mainNavigationReady,
    required bool reviewFlowReady,
    required bool technicalSummaryReady,
    required bool fieldOpsReady,
    required bool observabilityReady,
    required bool governanceReady,
    required bool assistiveReady,
  }) {
    final items = <ProductionReadinessItem>[
      ProductionReadinessItem(
        id: 'nav_main',
        title: 'Navegação principal consolidada',
        description: mainNavigationReady
            ? 'Os pontos de entrada principais estão definidos.'
            : 'Os pontos de entrada principais ainda não foram consolidados.',
        severity: ProductionReadinessSeverity.blocking,
        done: mainNavigationReady,
      ),
      ProductionReadinessItem(
        id: 'review_flow',
        title: 'Fluxo final operacional',
        description: reviewFlowReady
            ? 'O fluxo final de revisão está disponível.'
            : 'O fluxo final de revisão ainda não está consolidado.',
        severity: ProductionReadinessSeverity.blocking,
        done: reviewFlowReady,
      ),
      ProductionReadinessItem(
        id: 'technical_summary',
        title: 'Resumo técnico final',
        description: technicalSummaryReady
            ? 'O resumo técnico final está disponível.'
            : 'O resumo técnico final ainda não está disponível.',
        severity: ProductionReadinessSeverity.warning,
        done: technicalSummaryReady,
      ),
      ProductionReadinessItem(
        id: 'field_ops',
        title: 'Operação de campo',
        description: fieldOpsReady
            ? 'A operação de campo está disponível.'
            : 'A operação de campo ainda não está disponível.',
        severity: ProductionReadinessSeverity.warning,
        done: fieldOpsReady,
      ),
      ProductionReadinessItem(
        id: 'observability',
        title: 'Observabilidade',
        description: observabilityReady
            ? 'A camada de observabilidade está disponível.'
            : 'A camada de observabilidade ainda não está disponível.',
        severity: ProductionReadinessSeverity.info,
        done: observabilityReady,
      ),
      ProductionReadinessItem(
        id: 'governance',
        title: 'Governança local',
        description: governanceReady
            ? 'A governança local está disponível.'
            : 'A governança local ainda não está disponível.',
        severity: ProductionReadinessSeverity.info,
        done: governanceReady,
      ),
      ProductionReadinessItem(
        id: 'assistive',
        title: 'IA assistiva',
        description: assistiveReady
            ? 'A camada assistiva está disponível.'
            : 'A camada assistiva ainda não está disponível.',
        severity: ProductionReadinessSeverity.info,
        done: assistiveReady,
      ),
    ];

    return ProductionReadinessSummary(items: items);
  }
}
