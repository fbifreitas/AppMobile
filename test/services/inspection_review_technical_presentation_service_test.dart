import 'package:appmobile/config/checkin_step2_config.dart';
import 'package:appmobile/models/classification_audit_entry.dart';
import 'package:appmobile/models/inspection_technical_summary.dart';
import 'package:appmobile/models/technical_pending_matrix.dart';
import 'package:appmobile/models/technical_rule_result.dart';
import 'package:appmobile/services/inspection_review_technical_presentation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = InspectionReviewTechnicalPresentationService.instance;

  test('friendlyDescription maps stage to user-facing copy', () {
    final result = TechnicalRuleResult(
      id: 'capture-1',
      stage: TechnicalRuleStage.capture,
      title: 'Falta foto',
      description: 'Registrar evidência',
      severity: TechnicalRuleSeverity.blocking,
    );

    expect(service.friendlyDescription(result), contains('fotos capturadas'));
  });

  test('photoCountPolicyMessage reports min and max violations', () {
    final config = CheckinStep2Config(
      tituloTela: 'Tela',
      subtituloTela: 'Sub',
      tipoImovel: TipoImovel.urbano,
      camposFotos: const <CheckinStep2PhotoFieldConfig>[],
      gruposOpcoes: const <CheckinStep2OptionGroupConfig>[],
      minFotos: 2,
      maxFotos: 3,
    );

    expect(
      service.photoCountPolicyMessage(config: config, totalCaptures: 1),
      contains('Mínimo'),
    );
    expect(
      service.photoCountPolicyMessage(config: config, totalCaptures: 4),
      contains('Máximo'),
    );
  });

  test('closingBlockingMessage exposes blocking reason when finish is not allowed', () {
    const summary = InspectionTechnicalSummary(
      tipoImovel: 'Urbano',
      totalSubtipos: 1,
      subtiposComCobertura: 0,
      totalFotos: 0,
      completionPercent: 0,
      pendingMatrix: TechnicalPendingMatrix(
        items: <TechnicalRuleResult>[
          TechnicalRuleResult(
            id: 'checkin-1',
            stage: TechnicalRuleStage.checkin,
            title: 'Obrigatória',
            description: 'Foto ausente',
            severity: TechnicalRuleSeverity.blocking,
          ),
        ],
      ),
      audits: <ClassificationAuditEntry>[],
    );

    final message = service.closingBlockingMessage(
      technicalSummary: summary,
      justificationText: '',
    );

    expect(message, isNotNull);
  });
}
