import '../models/technical_check_requirement_input.dart';
import '../models/technical_evidence_input.dart';
import '../models/technical_rule_result.dart';

class InspectionTechnicalRulesService {
  const InspectionTechnicalRulesService();

  List<TechnicalRuleResult> evaluate({
    required String tipoImovel,
    required List<TechnicalEvidenceInput> evidences,
    required List<TechnicalCheckRequirementInput> requirements,
  }) {
    final results = <TechnicalRuleResult>[];

    for (final requirement in requirements) {
      if (!requirement.fulfilled) {
        results.add(
          TechnicalRuleResult(
            id: 'checkin_${requirement.title}',
            title: 'Item obrigatório do check-in pendente',
            description: '${requirement.title} precisa ser registrado antes do fechamento técnico.',
            severity: TechnicalRuleSeverity.blocking,
            stage: TechnicalRuleStage.checkin,
          ),
        );
      }
    }

    final grouped = <String, List<TechnicalEvidenceInput>>{};
    for (final evidence in evidences) {
      final key =
          evidence.targetItem.trim().isEmpty
              ? 'Sem subtipo'
              : evidence.targetItem.trim();
      grouped.putIfAbsent(key, () => <TechnicalEvidenceInput>[]).add(evidence);
    }

    final minimumCoverage = _minimumCoverageByTipo(tipoImovel);
    for (final entry in minimumCoverage.entries) {
      final captured = grouped[entry.key]?.length ?? 0;
      if (captured < entry.value) {
        results.add(
          TechnicalRuleResult(
            id: 'coverage_${entry.key}',
            title: 'Cobertura mínima insuficiente',
            description: '${entry.key} requer no mínimo ${entry.value} evidência(s) para aderência técnica.',
            subtipo: entry.key,
            severity: TechnicalRuleSeverity.blocking,
            stage: TechnicalRuleStage.capture,
          ),
        );
      }
    }

    for (final entry in grouped.entries) {
      final subtipo = entry.key;
      final items = entry.value;

      final fullyClassified = items.where((item) => item.isFullyClassified).length;
      if (fullyClassified == 0) {
        results.add(
          TechnicalRuleResult(
            id: 'audit_$subtipo',
            title: 'Subtipo sem cobertura classificada',
            description: '$subtipo precisa ter ao menos uma foto com elemento, material e estado classificados.',
            subtipo: subtipo,
            severity: TechnicalRuleSeverity.blocking,
            stage: TechnicalRuleStage.review,
          ),
        );
      }

      for (var index = 0; index < items.length; index++) {
        final item = items[index];

        if (!item.hasTargetQualifier) {
          results.add(
            TechnicalRuleResult(
              id: 'missing_element_${subtipo}_$index',
              title: 'Foto sem elemento definido',
              description: 'Há evidência em $subtipo sem definição do elemento fotografado.',
              subtipo: subtipo,
              severity: TechnicalRuleSeverity.advisory,
              stage: TechnicalRuleStage.review,
              justificationAllowed: true,
            ),
          );
        }

        if (item.hasTargetQualifier && !item.hasMaterial) {
          results.add(
            TechnicalRuleResult(
              id: 'missing_material_${subtipo}_$index',
              title: 'Material não informado',
              description: 'Há evidência em $subtipo com elemento definido, mas sem material.',
              subtipo: subtipo,
              severity: TechnicalRuleSeverity.advisory,
              stage: TechnicalRuleStage.review,
              justificationAllowed: true,
            ),
          );
        }

        if (item.hasTargetQualifier && !item.hasTargetCondition) {
          results.add(
            TechnicalRuleResult(
              id: 'missing_state_${subtipo}_$index',
              title: 'Estado de conservação não informado',
              description: 'Há evidência em $subtipo com elemento definido, mas sem estado de conservação.',
              subtipo: subtipo,
              severity: TechnicalRuleSeverity.advisory,
              stage: TechnicalRuleStage.review,
              justificationAllowed: true,
            ),
          );
        }

        if (subtipo.toLowerCase().contains('outro')) {
          results.add(
            TechnicalRuleResult(
              id: 'other_subtype_$index',
              title: 'Subtipo fora do catálogo principal',
              description: 'Evidência registrada em subtipo alternativo. Recomendado justificar tecnicamente.',
              subtipo: subtipo,
              severity: TechnicalRuleSeverity.advisory,
              stage: TechnicalRuleStage.finalization,
              justificationAllowed: true,
            ),
          );
        }
      }
    }

    return results;
  }

  Map<String, int> _minimumCoverageByTipo(String tipoImovel) {
    switch (tipoImovel.toLowerCase()) {
      case 'rural':
        return const <String, int>{
          'Acesso principal': 1,
          'Entrada da propriedade': 1,
          'Identificação / referência': 1,
        };
      case 'comercial':
        return const <String, int>{
          'Fachada': 1,
          'Logradouro': 1,
          'Acesso principal': 1,
        };
      case 'industrial':
        return const <String, int>{
          'Acesso principal': 1,
          'Fachada / portaria': 1,
          'Número / identificação': 1,
        };
      case 'urbano':
      default:
        return const <String, int>{
          'Fachada': 1,
          'Logradouro': 1,
          'Acesso ao imóvel': 1,
          'Entorno': 1,
        };
    }
  }
}
