import 'package:flutter/material.dart';

import '../../models/inspection_review_operational_models.dart';
import '../../models/inspection_review_models.dart';
import 'inspection_review_support_widgets.dart';

class InspectionReviewBlock extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const InspectionReviewBlock({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
        ),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class InspectionReviewSectionAccordion extends StatelessWidget {
  final String title;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;
  final Widget child;

  const InspectionReviewSectionAccordion({
    super.key,
    required this.title,
    required this.expanded,
    required this.onExpansionChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        children: [child],
      ),
    );
  }
}

class InspectionReviewAccordion extends StatelessWidget {
  final GlobalKey keyValue;
  final String title;
  final bool isOk;
  final String subtitle;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;
  final Widget child;

  const InspectionReviewAccordion({
    super.key,
    required this.keyValue,
    required this.title,
    required this.isOk,
    required this.subtitle,
    required this.expanded,
    required this.onExpansionChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final status = isOk ? ReviewVisualStatus.ok : ReviewVisualStatus.pending;

    return Container(
      key: keyValue,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: status.borderColor.withValues(alpha: 0.30)),
      ),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: status.subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ReviewStatusPill(status: status, label: isOk ? 'OK' : 'NOK'),
          ],
        ),
        children: [child],
      ),
    );
  }
}

class InspectionReviewClosingAccordion extends StatelessWidget {
  final String title;
  final bool expanded;
  final bool isDone;
  final ValueChanged<bool> onExpansionChanged;
  final Widget child;

  const InspectionReviewClosingAccordion({
    super.key,
    required this.title,
    required this.expanded,
    required this.isDone,
    required this.onExpansionChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? Colors.green.withValues(alpha: 0.28)
              : Colors.orange.withValues(alpha: 0.30),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            ReviewStatusPill(
              status: isDone ? ReviewVisualStatus.ok : ReviewVisualStatus.pending,
              label: isDone ? 'OK' : 'NOK',
            ),
          ],
        ),
        children: [child],
      ),
    );
  }
}

class InspectionReviewBulletLine extends StatelessWidget {
  final String text;

  const InspectionReviewBulletLine({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2, right: 8),
          child: Text('•', style: TextStyle(fontSize: 16)),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class InspectionReviewCompositionCard extends StatelessWidget {
  final InspectionReviewOperationalData operationalData;
  final VoidCallback onEditComposition;

  const InspectionReviewCompositionCard({
    super.key,
    required this.operationalData,
    required this.onEditComposition,
  });

  @override
  Widget build(BuildContext context) {
    return InspectionReviewBlock(
      title: 'Composição identificada',
      trailing: TextButton(
        onPressed: onEditComposition,
        child: const Text('Editar composição'),
      ),
      child: operationalData.compositions.isEmpty
          ? const Text('Nenhuma composição identificada até o momento.')
          : Column(
              children: operationalData.compositions
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InspectionReviewBulletLine(
                        text: [
                          entry.title,
                          ...entry.contextTrail,
                          ...entry.detailTrail,
                        ].where((part) => part.trim().isNotEmpty).join(' > '),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class InspectionReviewEvidenceCard extends StatelessWidget {
  final InspectionReviewOperationalData operationalData;

  const InspectionReviewEvidenceCard({
    super.key,
    required this.operationalData,
  });

  @override
  Widget build(BuildContext context) {
    return InspectionReviewBlock(
      title: 'Evidências registradas',
      child: operationalData.evidences.isEmpty
          ? const Text('Nenhuma evidência registrada até o momento.')
          : Column(
              children: operationalData.evidences
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InspectionReviewBulletLine(
                        text: [
                          ...entry.contextTrail,
                          entry.itemLabel,
                          if (entry.qualifiers.isNotEmpty)
                            entry.qualifiers.join(', '),
                        ].where((part) => part.trim().isNotEmpty).join(' > '),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class InspectionReviewPendingEntryCard extends StatelessWidget {
  final InspectionReviewPendingEntry entry;
  final VoidCallback onPressed;

  const InspectionReviewPendingEntryCard({
    super.key,
    required this.entry,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = switch (entry.target) {
      InspectionReviewPendingActionTarget.capture => FilledButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      InspectionReviewPendingActionTarget.fill => FilledButton.styleFrom(
        backgroundColor: Colors.green.shade600,
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      InspectionReviewPendingActionTarget.editComposition =>
        OutlinedButton.styleFrom(
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      InspectionReviewPendingActionTarget.finalization => FilledButton.styleFrom(
        backgroundColor: Colors.green.shade600,
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(
          color: Colors.blueGrey.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4, right: 8),
                  child: Text('•', style: TextStyle(fontSize: 16)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.reason,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (entry.title.trim() != entry.reason.trim()) ...[
                        const SizedBox(height: 3),
                        Text(
                          entry.title,
                          style: TextStyle(
                            color: Colors.blueGrey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          switch (entry.target) {
            InspectionReviewPendingActionTarget.editComposition => OutlinedButton(
              onPressed: onPressed,
              style: buttonStyle,
              child: Text(entry.ctaLabel),
            ),
            _ => FilledButton(
              onPressed: onPressed,
              style: buttonStyle,
              child: Text(entry.ctaLabel),
            ),
          },
        ],
      ),
    );
  }
}

class InspectionReviewPendingCard extends StatelessWidget {
  final InspectionReviewOperationalData operationalData;
  final ValueChanged<InspectionReviewPendingEntry> onPendingPressed;

  const InspectionReviewPendingCard({
    super.key,
    required this.operationalData,
    required this.onPendingPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InspectionReviewBlock(
      title: 'Pendências para encerrar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (operationalData.pendings.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.green.withValues(alpha: 0.08),
                border: Border.all(color: Colors.green.withValues(alpha: 0.20)),
              ),
              child: const Text(
                'Nenhuma pendência bloqueante encontrada.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          else
            ...operationalData.pendings.map(
              (entry) => InspectionReviewPendingEntryCard(
                entry: entry,
                onPressed: () => onPendingPressed(entry),
              ),
            ),
          if (operationalData.pendings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Resolva as pendências abaixo para concluir.',
                style: TextStyle(
                  color: Colors.blueGrey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class InspectionReviewNodeGroupList extends StatelessWidget {
  final List<InspectionReviewNodeGroup> groups;
  final String? expandedSubtype;
  final ValueChanged<String?> onExpandedSubtypeChanged;
  final VoidCallback onChanged;
  final ValueChanged<InspectionReviewNodeGroup> onApplySubtype;
  final void Function(
    InspectionReviewNodeGroup group,
    InspectionReviewEditableCapture source,
  )
  onApplySimilar;
  final ValueChanged<InspectionReviewNodeGroup> onAcceptSuggestions;
  final Future<void> Function(InspectionReviewEditableCapture item) onEditItem;

  const InspectionReviewNodeGroupList({
    super.key,
    required this.groups,
    required this.expandedSubtype,
    required this.onExpandedSubtypeChanged,
    required this.onChanged,
    required this.onApplySubtype,
    required this.onApplySimilar,
    required this.onAcceptSuggestions,
    required this.onEditItem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: groups
          .map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ReviewNodeCard(
                group: group,
                initiallyExpanded: expandedSubtype == null
                    ? group.pending > 0
                    : expandedSubtype == group.title,
                onExpansionChanged: (expanded) {
                  onExpandedSubtypeChanged(expanded ? group.title : null);
                },
                onChanged: onChanged,
                onApplySubtype: () => onApplySubtype(group),
                onApplySimilar: (source) => onApplySimilar(group, source),
                onAcceptSuggestions: () => onAcceptSuggestions(group),
                onEditItem: onEditItem,
              ),
            ),
          )
          .toList(),
    );
  }
}

class InspectionReviewMandatoryAccordionContent extends StatelessWidget {
  final List<InspectionReviewNodeGroup> mandatoryGroups;
  final List<InspectionReviewRequirementGroupStatus> visibleGroupedRequirements;
  final String? expandedSubtype;
  final ValueChanged<String?> onExpandedSubtypeChanged;
  final VoidCallback onChanged;
  final ValueChanged<InspectionReviewNodeGroup> onApplySubtype;
  final void Function(
    InspectionReviewNodeGroup group,
    InspectionReviewEditableCapture source,
  )
  onApplySimilar;
  final ValueChanged<InspectionReviewNodeGroup> onAcceptSuggestions;
  final Future<void> Function(InspectionReviewEditableCapture item) onEditItem;
  final ValueChanged<InspectionReviewRequirementStatus> onCaptureMissingRequirement;

  const InspectionReviewMandatoryAccordionContent({
    super.key,
    required this.mandatoryGroups,
    required this.visibleGroupedRequirements,
    required this.expandedSubtype,
    required this.onExpandedSubtypeChanged,
    required this.onChanged,
    required this.onApplySubtype,
    required this.onApplySimilar,
    required this.onAcceptSuggestions,
    required this.onEditItem,
    required this.onCaptureMissingRequirement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (mandatoryGroups.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sem cartões de captura obrigatória disponíveis.',
            ),
          )
        else
          InspectionReviewNodeGroupList(
            groups: mandatoryGroups,
            expandedSubtype: expandedSubtype,
            onExpandedSubtypeChanged: onExpandedSubtypeChanged,
            onChanged: onChanged,
            onApplySubtype: onApplySubtype,
            onApplySimilar: onApplySimilar,
            onAcceptSuggestions: onAcceptSuggestions,
            onEditItem: onEditItem,
          ),
        ...visibleGroupedRequirements.map(
          (group) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ReviewCheckinRequirementCard(
              status: group,
              onCapture: group.pendingStatus == null
                  ? null
                  : () => onCaptureMissingRequirement(group.pendingStatus!),
            ),
          ),
        ),
      ],
    );
  }
}

class InspectionReviewCapturedAccordionContent extends StatelessWidget {
  final List<InspectionReviewNodeGroup> capturedGroups;
  final String? expandedSubtype;
  final ValueChanged<String?> onExpandedSubtypeChanged;
  final VoidCallback onChanged;
  final ValueChanged<InspectionReviewNodeGroup> onApplySubtype;
  final void Function(
    InspectionReviewNodeGroup group,
    InspectionReviewEditableCapture source,
  )
  onApplySimilar;
  final ValueChanged<InspectionReviewNodeGroup> onAcceptSuggestions;
  final Future<void> Function(InspectionReviewEditableCapture item) onEditItem;

  const InspectionReviewCapturedAccordionContent({
    super.key,
    required this.capturedGroups,
    required this.expandedSubtype,
    required this.onExpandedSubtypeChanged,
    required this.onChanged,
    required this.onApplySubtype,
    required this.onApplySimilar,
    required this.onAcceptSuggestions,
    required this.onEditItem,
  });

  @override
  Widget build(BuildContext context) {
    return InspectionReviewNodeGroupList(
      groups: capturedGroups,
      expandedSubtype: expandedSubtype,
      onExpandedSubtypeChanged: onExpandedSubtypeChanged,
      onChanged: onChanged,
      onApplySubtype: onApplySubtype,
      onApplySimilar: onApplySimilar,
      onAcceptSuggestions: onAcceptSuggestions,
      onEditItem: onEditItem,
    );
  }
}
