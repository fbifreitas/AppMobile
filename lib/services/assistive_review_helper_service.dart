class AssistiveReviewHelperService {
  const AssistiveReviewHelperService();

  List<String> buildReviewHints({
    required int totalFotos,
    required int totalPendencias,
    required int totalBloqueiosTecnicos,
    required int totalJustificativasPendentes,
  }) {
    final hints = <String>[];

    if (totalFotos == 0) {
      hints.add('Nenhuma evidência foi registrada ainda. Capture fotos antes da revisão.');
    }
    if (totalPendencias > 0) {
      hints.add('Existem pendências operacionais que devem ser verificadas antes do encerramento.');
    }
    if (totalBloqueiosTecnicos > 0) {
      hints.add('Há bloqueios técnicos normativos impedindo a conclusão da vistoria.');
    }
    if (totalJustificativasPendentes > 0) {
      hints.add('Existem pendências técnicas não bloqueantes que exigem justificativa.');
    }
    if (hints.isEmpty) {
      hints.add('Fluxo consistente: não foram detectadas recomendações automáticas no momento.');
    }

    return hints;
  }
}
