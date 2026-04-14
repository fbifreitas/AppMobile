import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/technical_rule_result.dart';
import '../../services/voice_input_service.dart';
import '../technical_justification_card.dart';
import '../voice_text_field.dart';
import 'inspection_review_support_widgets.dart';

class InspectionTechnicalPendingStageAccordion extends StatelessWidget {
  final String title;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;
  final List<TechnicalRuleResult> items;
  final String Function(TechnicalRuleResult item) describeItem;
  final ValueChanged<TechnicalRuleResult> onPendingPressed;

  const InspectionTechnicalPendingStageAccordion({
    super.key,
    required this.title,
    required this.expanded,
    required this.onExpansionChanged,
    required this.items,
    required this.describeItem,
    required this.onPendingPressed,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final hasPending = items.isNotEmpty;
    final pendingLabel = hasPending
        ? strings.pendingItemsLabel(items.length)
        : strings.noPendingItemsAtStage;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasPending
              ? Colors.orange.withValues(alpha: 0.35)
              : Colors.green.withValues(alpha: 0.30),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pendingLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasPending
                          ? Colors.orange.shade800
                          : Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ReviewStatusPill(
              status:
                  hasPending ? ReviewVisualStatus.pending : ReviewVisualStatus.ok,
              label: hasPending ? 'NOK' : 'OK',
            ),
          ],
        ),
        children: [
          if (!hasPending)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(strings.noPendingAdjustmentsAtStage),
              ),
            )
          else
            ...items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: item.isBlocking
                        ? Colors.orange.withValues(alpha: 0.28)
                        : Colors.blueGrey.withValues(alpha: 0.28),
                  ),
                  color: item.isBlocking
                      ? Colors.orange.withValues(alpha: 0.06)
                      : Colors.blueGrey.withValues(alpha: 0.06),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      describeItem(item),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => onPendingPressed(item),
                      icon: const Icon(Icons.near_me_outlined, size: 16),
                      label: Text(strings.goToPendingItem),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class InspectionTechnicalPendingAccordionsSection extends StatelessWidget {
  final bool technicalCheckinExpanded;
  final bool technicalCaptureExpanded;
  final bool technicalReviewExpanded;
  final bool technicalFinalizationExpanded;
  final int checkinDone;
  final int checkinTotal;
  final int captureDone;
  final int captureTotal;
  final int reviewDone;
  final int reviewTotal;
  final int finalizationDone;
  final int finalizationTotal;
  final List<TechnicalRuleResult> checkinItems;
  final List<TechnicalRuleResult> captureItems;
  final List<TechnicalRuleResult> reviewItems;
  final List<TechnicalRuleResult> finalizationItems;
  final ValueChanged<bool> onCheckinExpansionChanged;
  final ValueChanged<bool> onCaptureExpansionChanged;
  final ValueChanged<bool> onReviewExpansionChanged;
  final ValueChanged<bool> onFinalizationExpansionChanged;
  final String Function(TechnicalRuleResult item) describeItem;
  final ValueChanged<TechnicalRuleResult> onPendingPressed;

  const InspectionTechnicalPendingAccordionsSection({
    super.key,
    required this.technicalCheckinExpanded,
    required this.technicalCaptureExpanded,
    required this.technicalReviewExpanded,
    required this.technicalFinalizationExpanded,
    required this.checkinDone,
    required this.checkinTotal,
    required this.captureDone,
    required this.captureTotal,
    required this.reviewDone,
    required this.reviewTotal,
    required this.finalizationDone,
    required this.finalizationTotal,
    required this.checkinItems,
    required this.captureItems,
    required this.reviewItems,
    required this.finalizationItems,
    required this.onCheckinExpansionChanged,
    required this.onCaptureExpansionChanged,
    required this.onReviewExpansionChanged,
    required this.onFinalizationExpansionChanged,
    required this.describeItem,
    required this.onPendingPressed,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.pendingNavigationHint),
        const SizedBox(height: 10),
        InspectionTechnicalPendingStageAccordion(
          title: strings.checkInProgress(checkinDone, checkinTotal),
          expanded: technicalCheckinExpanded,
          onExpansionChanged: onCheckinExpansionChanged,
          items: checkinItems,
          describeItem: describeItem,
          onPendingPressed: onPendingPressed,
        ),
        InspectionTechnicalPendingStageAccordion(
          title: strings.captureProgress(captureDone, captureTotal),
          expanded: technicalCaptureExpanded,
          onExpansionChanged: onCaptureExpansionChanged,
          items: captureItems,
          describeItem: describeItem,
          onPendingPressed: onPendingPressed,
        ),
        InspectionTechnicalPendingStageAccordion(
          title: strings.reviewProgress(reviewDone, reviewTotal),
          expanded: technicalReviewExpanded,
          onExpansionChanged: onReviewExpansionChanged,
          items: reviewItems,
          describeItem: describeItem,
          onPendingPressed: onPendingPressed,
        ),
        InspectionTechnicalPendingStageAccordion(
          title: strings.finalizationProgress(
            finalizationDone,
            finalizationTotal,
          ),
          expanded: technicalFinalizationExpanded,
          onExpansionChanged: onFinalizationExpansionChanged,
          items: finalizationItems,
          describeItem: describeItem,
          onPendingPressed: onPendingPressed,
        ),
      ],
    );
  }
}

class InspectionReviewClosingCard extends StatelessWidget {
  final GlobalKey sectionKey;
  final bool annotationRequired;
  final bool annotationDone;
  final TextEditingController technicalJustificationController;
  final FocusNode technicalJustificationFocusNode;
  final VoiceInputService voiceService;
  final ValueChanged<String> onTechnicalJustificationChanged;
  final TextEditingController noteController;
  final ValueChanged<String> onObservationChanged;
  final int totalPending;
  final String? photoPolicyMessage;
  final String? blockingMessage;

  const InspectionReviewClosingCard({
    super.key,
    required this.sectionKey,
    required this.annotationRequired,
    required this.annotationDone,
    required this.technicalJustificationController,
    required this.technicalJustificationFocusNode,
    required this.voiceService,
    required this.onTechnicalJustificationChanged,
    required this.noteController,
    required this.onObservationChanged,
    required this.totalPending,
    required this.photoPolicyMessage,
    required this.blockingMessage,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      key: sectionKey,
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (annotationRequired) ...[
            Text(
              strings.technicalJustification,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            TechnicalJustificationCard(
              controller: technicalJustificationController,
              voiceService: voiceService,
              onChanged: onTechnicalJustificationChanged,
              focusNode: technicalJustificationFocusNode,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            strings.finalNote,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          VoiceTextField(
            controller: noteController,
            labelText: strings.finalNote,
            minLines: 3,
            maxLines: 4,
            voiceService: voiceService,
            onChanged: onObservationChanged,
            helperText: strings.finalNoteHelper,
          ),
          if (totalPending > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                strings.attentionPendingItems(totalPending),
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          if (annotationRequired && !annotationDone)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                strings.fillTechnicalJustification,
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          if (photoPolicyMessage != null && photoPolicyMessage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                photoPolicyMessage!,
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          if (blockingMessage != null && blockingMessage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                blockingMessage!,
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
