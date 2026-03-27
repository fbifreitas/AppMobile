class OperationalOutputService {
  const OperationalOutputService();

  List<String> buildChecklist({
    required bool hasReviewFlow,
    required bool hasTechnicalSummary,
    required bool hasObservabilityCenter,
    required bool hasGovernanceCenter,
  }) {
    return <String>[
      hasReviewFlow
          ? 'Fluxo final de revisão disponível'
          : 'Fluxo final de revisão pendente',
      hasTechnicalSummary
          ? 'Resumo técnico final disponível'
          : 'Resumo técnico final pendente',
      hasObservabilityCenter
          ? 'Central de observabilidade disponível'
          : 'Central de observabilidade pendente',
      hasGovernanceCenter
          ? 'Central de governança local disponível'
          : 'Central de governança local pendente',
      'Saída operacional preparada para checklist final de implantação',
    ];
  }
}
