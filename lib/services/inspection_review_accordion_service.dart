import 'inspection_review_requirement_service.dart';

enum InspectionReviewCaptureStatusData { pending, suggested, classified }

class InspectionReviewCaptureItemData {
  final String filePath;
  final String ambiente;
  final String? elemento;
  final InspectionReviewCaptureStatusData status;

  const InspectionReviewCaptureItemData({
    required this.filePath,
    required this.ambiente,
    required this.elemento,
    required this.status,
  });

  String get targetItem => ambiente;
  String? get targetQualifier => elemento;
}

class InspectionReviewAccordionData {
  final Set<String> mandatoryCapturedPaths;
  final List<InspectionReviewRequirementGroupData> visibleRequirementGroups;
  final int checkinPendencias;
  final bool hasCheckinPending;
  final int capturedPendencias;
  final int requiredDone;
  final int requiredTotal;
  final int capturedClassified;
  final int capturedTotal;
  final bool hasCapturedPending;

  const InspectionReviewAccordionData({
    required this.mandatoryCapturedPaths,
    required this.visibleRequirementGroups,
    required this.checkinPendencias,
    required this.hasCheckinPending,
    required this.capturedPendencias,
    required this.requiredDone,
    required this.requiredTotal,
    required this.capturedClassified,
    required this.capturedTotal,
    required this.hasCapturedPending,
  });
}

class InspectionReviewAccordionService {
  const InspectionReviewAccordionService();

  static const InspectionReviewAccordionService instance =
      InspectionReviewAccordionService();

  InspectionReviewAccordionData build({
    required List<InspectionReviewCaptureItemData> items,
    required List<InspectionReviewRequirementStatusData> checkinStatuses,
    required List<InspectionReviewRequirementGroupData> groupedRequirements,
    required String Function(String?) normalizeComparableText,
  }) {
    final mandatoryCapturedPaths = <String>{};

    for (final status in checkinStatuses.where((status) => status.isDone)) {
      for (final item in items) {
        final sameAmbiente =
            normalizeComparableText(item.targetItem) ==
            normalizeComparableText(status.field.cameraAmbiente);
        final sameElemento =
            status.field.cameraElementoInicial == null ||
            normalizeComparableText(item.targetQualifier) ==
                normalizeComparableText(status.field.cameraElementoInicial);
        final notUsed = !mandatoryCapturedPaths.contains(item.filePath);
        if (sameAmbiente && sameElemento && notUsed) {
          mandatoryCapturedPaths.add(item.filePath);
          break;
        }
      }
    }

    final visibleRequirementGroups =
        groupedRequirements.where((group) {
          if (!group.isDone) {
            return true;
          }
          for (final status in group.statuses.where((status) => status.isDone)) {
            final represented = items.any((item) {
              final sameAmbiente =
                  normalizeComparableText(item.targetItem) ==
                  normalizeComparableText(status.field.cameraAmbiente);
              final sameElemento =
                  status.field.cameraElementoInicial == null ||
                  normalizeComparableText(item.targetQualifier) ==
                      normalizeComparableText(status.field.cameraElementoInicial);
              return mandatoryCapturedPaths.contains(item.filePath) &&
                  sameAmbiente &&
                  sameElemento;
            });
            if (!represented) {
              return true;
            }
          }
          return false;
        }).toList();

    final checkinPendencias =
        checkinStatuses.where((status) => !status.isDone).length;
    final mandatoryItems =
        items.where((item) => mandatoryCapturedPaths.contains(item.filePath));
    final hasCheckinPending =
        checkinPendencias > 0 ||
        mandatoryItems.any(
          (item) => item.status != InspectionReviewCaptureStatusData.classified,
        );
    final capturedPendencias =
        items
            .where((item) => !mandatoryCapturedPaths.contains(item.filePath))
            .where((item) => item.status == InspectionReviewCaptureStatusData.pending)
            .length;
    final requiredDone = checkinStatuses.where((status) => status.isDone).length;
    final requiredTotal = checkinStatuses.length;
    final capturedClassified =
        items
            .where((item) => item.status == InspectionReviewCaptureStatusData.classified)
            .length;
    final capturedTotal = items.length;

    return InspectionReviewAccordionData(
      mandatoryCapturedPaths: mandatoryCapturedPaths,
      visibleRequirementGroups: visibleRequirementGroups,
      checkinPendencias: checkinPendencias,
      hasCheckinPending: hasCheckinPending,
      capturedPendencias: capturedPendencias,
      requiredDone: requiredDone,
      requiredTotal: requiredTotal,
      capturedClassified: capturedClassified,
      capturedTotal: capturedTotal,
      hasCapturedPending: capturedPendencias > 0,
    );
  }
}
