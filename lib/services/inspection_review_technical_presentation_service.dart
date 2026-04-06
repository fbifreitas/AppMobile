import '../config/checkin_step2_config.dart';
import '../models/inspection_technical_summary.dart';
import '../models/technical_rule_result.dart';

class InspectionReviewTechnicalPresentationService {
  const InspectionReviewTechnicalPresentationService();

  static const InspectionReviewTechnicalPresentationService instance =
      InspectionReviewTechnicalPresentationService();

  String friendlyDescription(TechnicalRuleResult item) {
    switch (item.stage) {
      case TechnicalRuleStage.checkin:
        return 'No check-in obrigatório: ${item.description}';
      case TechnicalRuleStage.capture:
        return 'Nas fotos capturadas: ${item.description}';
      case TechnicalRuleStage.review:
        return 'Na revisão das fotos: ${item.description}';
      case TechnicalRuleStage.finalization:
        return 'Na etapa de finalização: ${item.description}';
    }
  }

  String? photoCountPolicyMessage({
    required CheckinStep2Config config,
    required int totalCaptures,
  }) {
    final minMsg =
        totalCaptures < config.minFotos
            ? 'Mínimo de ${config.minFotos} foto(s) não atingido.'
            : null;
    final maxFotos = config.maxFotos;
    final maxMsg =
        maxFotos != null && maxFotos > 0 && totalCaptures > maxFotos
            ? 'Máximo de $maxFotos foto(s) excedido.'
            : null;
    final message = [
      if (minMsg != null) minMsg,
      if (maxMsg != null) maxMsg,
    ].join(' ');
    return message.trim().isEmpty ? null : message;
  }

  String? closingBlockingMessage({
    required InspectionTechnicalSummary technicalSummary,
    required String justificationText,
  }) {
    if (technicalSummary.canProceedWith(justificationText)) {
      return null;
    }

    return technicalSummary.pendingMatrix.hasBlocking
        ? 'Conclusão técnica bloqueada até resolver as pendências normativas.'
        : 'Preencha a anotação do vistoriador para concluir a vistoria.';
  }
}
