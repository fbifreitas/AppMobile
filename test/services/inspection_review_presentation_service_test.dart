import 'package:appmobile/services/inspection_review_presentation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = InspectionReviewPresentationService.instance;

  test('buildSummary counts pending suggested and classified items', () {
    final summary = service.buildSummary(
      itemStatuses: const <InspectionReviewItemStatusData>[
        InspectionReviewItemStatusData.pending,
        InspectionReviewItemStatusData.suggested,
        InspectionReviewItemStatusData.classified,
      ],
      missingCheckin: 2,
      photoCountPolicyPending: 1,
    );

    expect(summary.total, 3);
    expect(summary.photoPending, 1);
    expect(summary.suggested, 1);
    expect(summary.classified, 1);
    expect(summary.totalPending, 4);
  });

  test('buildGroups orders groups by pending and then title', () {
    final groups = service.buildGroups(
      const <InspectionReviewGroupingItemData>[
        InspectionReviewGroupingItemData(
          ambiente: 'Sala',
          status: InspectionReviewItemStatusData.classified,
        ),
        InspectionReviewGroupingItemData(
          ambiente: 'Quarto',
          status: InspectionReviewItemStatusData.pending,
        ),
        InspectionReviewGroupingItemData(
          ambiente: 'Quarto',
          status: InspectionReviewItemStatusData.suggested,
        ),
      ],
    );

    expect(groups.length, 2);
    expect(groups.first.title, 'Quarto');
    expect(groups.first.pending, 1);
    expect(groups.first.suggested, 1);
  });

  test('buildPendingShortcut resolves expansion and target by stage', () {
    final shortcut = service.buildPendingShortcut(
      stage: 'capture',
      subtipo: 'Quarto 2',
    );

    expect(shortcut.expandTechnicalPending, isTrue);
    expect(shortcut.expandReview, isTrue);
    expect(shortcut.expandCapturedAccordion, isTrue);
    expect(shortcut.expandedSubtype, 'Quarto 2');
    expect(
      shortcut.target,
      InspectionReviewShortcutTargetData.capturedPhotos,
    );
  });

  test('buildMandatorySection and buildCapturedSection expose subtitle state', () {
    final mandatory = service.buildMandatorySection(
      checkinPendencias: 1,
      requiredDone: 2,
      requiredTotal: 3,
      hasCheckinPending: true,
    );
    final captured = service.buildCapturedSection(
      capturedPendencias: 0,
      capturedClassified: 4,
      capturedTotal: 4,
      hasCapturedPending: false,
    );

    expect(mandatory.isOk, isFalse);
    expect(mandatory.subtitle, contains('1 pend'));
    expect(captured.isOk, isTrue);
    expect(captured.subtitle, contains('4/4'));
  });
}
