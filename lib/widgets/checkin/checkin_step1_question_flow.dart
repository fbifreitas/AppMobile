import 'package:flutter/material.dart';

import '../../config/inspection_menu_package.dart';
import '../../l10n/app_strings.dart';
import '../../services/checkin_dynamic_config_service.dart';
import '../../theme/app_colors.dart';
import 'checkin_question_accordion.dart';
import 'checkin_step1_section_header.dart';

class CheckinStep1QuestionFlow extends StatelessWidget {
  final bool? clientePresente;
  final String? tipoImovel;
  final String? subtipoImovel;
  final String contextLevelId;
  final String questionClienteId;
  final String questionTipoId;
  final String questionSubtipoId;
  final Map<String, String> niveisSelecionados;
  final List<String> tipos;
  final List<String> subtipos;
  final List<ConfigLevelDefinition> activeLevels;
  final bool submittingClientAbsent;
  final bool step1SectionExpanded;
  final String? resolvedExpandedId;
  final int answered;
  final int total;
  final bool isDone;
  final CheckinStep1UiConfig step1Ui;
  final String Function(ConfigLevelDefinition level) labelForStep1Level;
  final String Function(String levelId) levelQuestionId;
  final List<String> Function(ConfigLevelDefinition level) optionsForLevel;
  final bool Function() shouldShowStep2Action;
  final VoidCallback onSectionTap;
  final ValueChanged<String> onToggleQuestion;
  final Future<void> Function() onClienteVoiceTap;
  final Future<void> Function() onTipoVoiceTap;
  final Future<void> Function() onSubtipoVoiceTap;
  final Future<void> Function(
    ConfigLevelDefinition level,
    List<String> options,
  )
  onLevelVoiceTap;
  final Future<void> Function() onClientePresenteYes;
  final Future<void> Function() onClientePresenteNo;
  final Future<void> Function(String tipo) onTipoSelected;
  final Future<void> Function(String subtipo) onSubtipoSelected;
  final Future<void> Function(ConfigLevelDefinition level, String option)
  onLevelSelected;
  final Widget? step2Action;

  const CheckinStep1QuestionFlow({
    super.key,
    required this.clientePresente,
    required this.tipoImovel,
    required this.subtipoImovel,
    required this.contextLevelId,
    required this.questionClienteId,
    required this.questionTipoId,
    required this.questionSubtipoId,
    required this.niveisSelecionados,
    required this.tipos,
    required this.subtipos,
    required this.activeLevels,
    required this.submittingClientAbsent,
    required this.step1SectionExpanded,
    required this.resolvedExpandedId,
    required this.answered,
    required this.total,
    required this.isDone,
    required this.step1Ui,
    required this.labelForStep1Level,
    required this.levelQuestionId,
    required this.optionsForLevel,
    required this.shouldShowStep2Action,
    required this.onSectionTap,
    required this.onToggleQuestion,
    required this.onClienteVoiceTap,
    required this.onTipoVoiceTap,
    required this.onSubtipoVoiceTap,
    required this.onLevelVoiceTap,
    required this.onClientePresenteYes,
    required this.onClientePresenteNo,
    required this.onTipoSelected,
    required this.onSubtipoSelected,
    required this.onLevelSelected,
    required this.step2Action,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final statusColor = isDone ? AppColors.success : AppColors.warning;
    final statusBg = isDone ? AppColors.successLight : AppColors.warningLight;

    final widgets = <Widget>[
      CheckinStep1SectionHeader(
        answered: answered,
        total: total,
        isDone: isDone,
        expanded: step1SectionExpanded,
        statusColor: statusColor,
        statusBackground: statusBg,
        onTap: onSectionTap,
      ),
    ];

    if (!step1SectionExpanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      );
    }

    final step1Cards = <Widget>[];

    if (step1Ui.clientePresenteVisible) {
      step1Cards.add(
        CheckinQuestionAccordion(
          question: strings.tr('Cliente esta presente?', 'Is the client present?'),
          answer: clientePresente == null
              ? null
              : (clientePresente!
                  ? strings.tr('Sim', 'Yes')
                  : strings.tr('Nao', 'No')),
          expanded: resolvedExpandedId == questionClienteId,
          onToggle: () => onToggleQuestion(questionClienteId),
          onVoiceTap: onClienteVoiceTap,
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(strings.tr('Sim', 'Yes')),
                selected: clientePresente == true,
                onSelected:
                    submittingClientAbsent ? null : (_) => onClientePresenteYes(),
              ),
              ChoiceChip(
                label: Text(strings.tr('Nao', 'No')),
                selected: clientePresente == false,
                onSelected:
                    submittingClientAbsent ? null : (_) => onClientePresenteNo(),
              ),
            ],
          ),
        ),
      );
    }

    if (clientePresente == true && step1Ui.menuTipoVisible) {
      step1Cards.add(const SizedBox(height: 10));
      step1Cards.add(
        CheckinQuestionAccordion(
          question: strings.tr('Tipo de imovel', 'Property type'),
          answer: tipoImovel,
          expanded: resolvedExpandedId == questionTipoId,
          onToggle: () => onToggleQuestion(questionTipoId),
          onVoiceTap: onTipoVoiceTap,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tipos
                .map(
                  (tipo) => ChoiceChip(
                    label: Text(tipo),
                    selected: tipoImovel == tipo,
                    onSelected: (_) => onTipoSelected(tipo),
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    if (clientePresente == true && tipoImovel != null && step1Ui.menuSubtipoVisible) {
      step1Cards.add(const SizedBox(height: 10));
      step1Cards.add(
        CheckinQuestionAccordion(
          question: strings.tr('Subtipo', 'Subtype'),
          answer: subtipoImovel,
          expanded: resolvedExpandedId == questionSubtipoId,
          onToggle: () => onToggleQuestion(questionSubtipoId),
          onVoiceTap: onSubtipoVoiceTap,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subtipos
                .map(
                  (subtipo) => ChoiceChip(
                    label: Text(subtipo),
                    selected: subtipoImovel == subtipo,
                    onSelected: (_) => onSubtipoSelected(subtipo),
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    if (clientePresente == true && subtipoImovel != null) {
      var hasPending = false;
      for (final level in activeLevels) {
        final questionId = levelQuestionId(level.id);
        final options = optionsForLevel(level);
        final selected = niveisSelecionados[level.id];
        final answeredLevel = selected != null && selected.trim().isNotEmpty;

        if (!answeredLevel && hasPending) {
          break;
        }

        step1Cards.add(const SizedBox(height: 10));
        step1Cards.add(
          CheckinQuestionAccordion(
            question: labelForStep1Level(level),
            answer: selected,
            expanded: resolvedExpandedId == questionId,
            onToggle: () => onToggleQuestion(questionId),
            onVoiceTap: () => onLevelVoiceTap(level, options),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options
                  .map(
                    (option) => ChoiceChip(
                      label: Text(option),
                      selected: selected == option,
                      onSelected: (_) => onLevelSelected(level, option),
                    ),
                  )
                  .toList(),
            ),
          ),
        );

        if (!answeredLevel) {
          hasPending = true;
        }
      }
    }

    if (clientePresente == true && shouldShowStep2Action() && step1Ui.botaoEtapa2Visible) {
      step1Cards.add(const SizedBox(height: 16));
      if (step2Action != null) {
        step1Cards.add(step2Action!);
      }
    }

    widgets.add(const SizedBox(height: 12));
    widgets.add(
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: step1Cards,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
