import '../models/technical_check_requirement_input.dart';
import '../models/technical_evidence_input.dart';
import '../models/technical_rule_result.dart';

class InspectionTechnicalRulesService {
  const InspectionTechnicalRulesService();

  List<TechnicalRuleResult> evaluate({
    required String tipoImovel,
    required List<TechnicalEvidenceInput> evidences,
    required List<InspectionNormativeRequirementInput> requirements,
    required List<InspectionCaptureCoverageRequirementInput> coverageRequirements,
  }) {
    final results = <TechnicalRuleResult>[];

    for (final requirement in requirements) {
      if (!requirement.fulfilled) {
        results.add(
          TechnicalRuleResult(
            id: 'checkin_${requirement.title}',
            title: 'Item obrigatorio do check-in pendente',
            description:
                '${requirement.title} precisa ser registrado antes do fechamento tecnico.',
            severity: TechnicalRuleSeverity.blocking,
            stage: TechnicalRuleStage.checkin,
          ),
        );
      }
    }

    final grouped = <String, List<TechnicalEvidenceInput>>{};
    for (final evidence in evidences) {
      final key =
          evidence.subtipo.trim().isEmpty ? 'Sem subtipo' : evidence.subtipo.trim();
      grouped.putIfAbsent(key, () => <TechnicalEvidenceInput>[]).add(evidence);
    }

    for (final requirement in coverageRequirements) {
      final items =
          grouped[requirement.subtipo]?.toList() ??
          const <TechnicalEvidenceInput>[];
      final requiredElement = requirement.elemento?.trim();
      final hasCoverage = items.any((item) {
        if (requiredElement == null || requiredElement.isEmpty) {
          return true;
        }
        return (item.elemento?.trim() ?? '') == requiredElement;
      });

      if (!hasCoverage) {
        results.add(
          TechnicalRuleResult(
            id:
                'coverage_${requirement.subtipo}_${requiredElement == null || requiredElement.isEmpty ? 'any' : requiredElement}',
            title: 'Cobertura minima insuficiente',
            description:
                requiredElement == null || requiredElement.isEmpty
                    ? '${requirement.title} precisa ter ao menos uma evidencia registrada.'
                    : '${requirement.title} precisa ter ao menos uma evidencia registrada com $requiredElement.',
            subtipo: requirement.subtipo,
            severity: TechnicalRuleSeverity.blocking,
            stage: TechnicalRuleStage.capture,
          ),
        );
      }
    }

    for (final entry in grouped.entries) {
      final subtipo = entry.key;
      final items = entry.value;

      final fullyClassified =
          items.where((item) => item.isFullyClassified).length;
      if (fullyClassified == 0) {
        results.add(
          TechnicalRuleResult(
            id: 'audit_$subtipo',
            title: 'Subtipo sem cobertura classificada',
            description:
                '$subtipo precisa ter ao menos uma foto com classificacao completa para o contexto capturado.',
            subtipo: subtipo,
            severity: TechnicalRuleSeverity.blocking,
            stage: TechnicalRuleStage.review,
          ),
        );
      }

      for (var index = 0; index < items.length; index++) {
        final item = items[index];

        if (item.requiresElemento && !item.hasElemento) {
          results.add(
            TechnicalRuleResult(
              id: 'missing_element_${subtipo}_$index',
              title: 'Foto sem elemento definido',
              description:
                  'Ha evidencia em $subtipo sem definicao do elemento fotografado.',
              subtipo: subtipo,
              severity: TechnicalRuleSeverity.advisory,
              stage: TechnicalRuleStage.review,
              justificationAllowed: true,
            ),
          );
        }

        if (item.requiresMaterial && item.hasElemento && !item.hasMaterial) {
          results.add(
            TechnicalRuleResult(
              id: 'missing_material_${subtipo}_$index',
              title: 'Material nao informado',
              description:
                  'Ha evidencia em $subtipo com elemento definido, mas sem material.',
              subtipo: subtipo,
              severity: TechnicalRuleSeverity.advisory,
              stage: TechnicalRuleStage.review,
              justificationAllowed: true,
            ),
          );
        }

        if (item.requiresEstado && item.hasElemento && !item.hasEstado) {
          results.add(
            TechnicalRuleResult(
              id: 'missing_state_${subtipo}_$index',
              title: 'Estado de conservacao nao informado',
              description:
                  'Ha evidencia em $subtipo com elemento definido, mas sem estado de conservacao.',
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
              title: 'Subtipo fora do catalogo principal',
              description:
                  'Evidencia registrada em subtipo alternativo. Recomendado justificar tecnicamente.',
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
}
