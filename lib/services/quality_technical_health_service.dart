import '../models/stability_check_result.dart';

class QualityTechnicalHealthService {
  const QualityTechnicalHealthService();

  List<StabilityCheckResult> build({
    required bool technicalSummaryAvailable,
    required bool pendingMatrixAvailable,
    required bool justificationFlowAvailable,
    required int technicalBlockingCount,
  }) {
    return <StabilityCheckResult>[
      StabilityCheckResult(
        id: 'technical_summary',
        title: 'Resumo técnico disponível',
        description: technicalSummaryAvailable
            ? 'O resumo técnico final está integrado ao fluxo.'
            : 'O resumo técnico final não foi localizado.',
        severity: StabilityCheckSeverity.blocking,
        passed: technicalSummaryAvailable,
        category: 'technical',
      ),
      StabilityCheckResult(
        id: 'technical_matrix',
        title: 'Matriz de pendências disponível',
        description: pendingMatrixAvailable
            ? 'A matriz de pendências técnicas está ativa.'
            : 'A matriz de pendências técnicas não foi localizada.',
        severity: StabilityCheckSeverity.blocking,
        passed: pendingMatrixAvailable,
        category: 'technical',
      ),
      StabilityCheckResult(
        id: 'technical_justification',
        title: 'Fluxo de justificativa técnica disponível',
        description: justificationFlowAvailable
            ? 'O fluxo de justificativa técnica está presente.'
            : 'O fluxo de justificativa técnica não foi localizado.',
        severity: StabilityCheckSeverity.warning,
        passed: justificationFlowAvailable,
        category: 'technical',
      ),
      StabilityCheckResult(
        id: 'technical_blocking_count',
        title: 'Bloqueios técnicos monitorados',
        description: 'Há $technicalBlockingCount bloqueio(s) técnico(s) no cenário atual.',
        severity: StabilityCheckSeverity.info,
        passed: true,
        category: 'technical',
      ),
    ];
  }
}
