class InspectionReviewSummaryData {
  final int total;
  final int photoPending;
  final int missingCheckin;
  final int photoCountPolicyPending;
  final int suggested;
  final int classified;

  const InspectionReviewSummaryData({
    required this.total,
    required this.photoPending,
    required this.missingCheckin,
    required this.photoCountPolicyPending,
    required this.suggested,
    required this.classified,
  });

  int get totalPending =>
      photoPending + missingCheckin + photoCountPolicyPending;
}

enum InspectionReviewItemStatusData { pending, suggested, classified }

enum InspectionReviewShortcutTargetData {
  checkinPending,
  capturedPhotos,
  closing,
}

class InspectionReviewPendingShortcutData {
  final bool expandTechnicalPending;
  final bool expandReview;
  final bool expandCheckinAccordion;
  final bool expandCapturedAccordion;
  final bool expandClosing;
  final String? expandedSubtype;
  final InspectionReviewShortcutTargetData target;
  final int scrollDelayMs;
  final String snackbarMessage;

  const InspectionReviewPendingShortcutData({
    required this.expandTechnicalPending,
    required this.expandReview,
    required this.expandCheckinAccordion,
    required this.expandCapturedAccordion,
    required this.expandClosing,
    required this.expandedSubtype,
    required this.target,
    required this.scrollDelayMs,
    required this.snackbarMessage,
  });
}

class InspectionReviewAccordionSectionData {
  final bool isOk;
  final String subtitle;

  const InspectionReviewAccordionSectionData({
    required this.isOk,
    required this.subtitle,
  });
}

class InspectionReviewGroupingItemData {
  final String? ambiente;
  final InspectionReviewItemStatusData status;

  const InspectionReviewGroupingItemData({
    required this.ambiente,
    required this.status,
  });

  String? get targetItem => ambiente;
}

class InspectionReviewGroupData {
  final String title;
  final int pending;
  final int suggested;
  final int classified;

  const InspectionReviewGroupData({
    required this.title,
    required this.pending,
    required this.suggested,
    required this.classified,
  });
}

class InspectionReviewPresentationService {
  const InspectionReviewPresentationService();

  static const InspectionReviewPresentationService instance =
      InspectionReviewPresentationService();

  InspectionReviewSummaryData buildSummary({
    required List<InspectionReviewItemStatusData> itemStatuses,
    required int missingCheckin,
    required int photoCountPolicyPending,
  }) {
    final photoPending =
        itemStatuses
            .where((status) => status == InspectionReviewItemStatusData.pending)
            .length;
    final suggested =
        itemStatuses
            .where(
              (status) => status == InspectionReviewItemStatusData.suggested,
            )
            .length;
    final classified =
        itemStatuses
            .where(
              (status) => status == InspectionReviewItemStatusData.classified,
            )
            .length;

    return InspectionReviewSummaryData(
      total: itemStatuses.length,
      photoPending: photoPending,
      missingCheckin: missingCheckin,
      photoCountPolicyPending: photoCountPolicyPending,
      suggested: suggested,
      classified: classified,
    );
  }

  List<InspectionReviewGroupData> buildGroups(
    List<InspectionReviewGroupingItemData> items,
  ) {
    final grouped = <String, List<InspectionReviewGroupingItemData>>{};

    for (final item in items) {
      final key =
          item.targetItem == null || item.targetItem!.trim().isEmpty
              ? 'Sem subtipo'
              : item.targetItem!.trim();
      grouped.putIfAbsent(key, () => <InspectionReviewGroupingItemData>[]).add(
        item,
      );
    }

    final groups =
        grouped.entries.map((entry) {
          final values = entry.value;
          return InspectionReviewGroupData(
            title: entry.key,
            pending:
                values
                    .where(
                      (item) =>
                          item.status == InspectionReviewItemStatusData.pending,
                    )
                    .length,
            suggested:
                values
                    .where(
                      (item) =>
                          item.status ==
                          InspectionReviewItemStatusData.suggested,
                    )
                    .length,
            classified:
                values
                    .where(
                      (item) =>
                          item.status ==
                          InspectionReviewItemStatusData.classified,
                    )
                    .length,
          );
        }).toList();

    groups.sort((a, b) {
      if (a.pending != b.pending) return b.pending.compareTo(a.pending);
      if (a.suggested != b.suggested) return b.suggested.compareTo(a.suggested);
      return a.title.compareTo(b.title);
    });

    return groups;
  }

  InspectionReviewAccordionSectionData buildMandatorySection({
    required int checkinPendencias,
    required int requiredDone,
    required int requiredTotal,
    required bool hasCheckinPending,
  }) {
    return InspectionReviewAccordionSectionData(
      isOk: !hasCheckinPending,
      subtitle:
          hasCheckinPending
              ? '$checkinPendencias pendência(s) para captura • progresso $requiredDone/$requiredTotal'
              : 'Todas as fotos obrigatórias foram registradas • progresso $requiredDone/$requiredTotal',
    );
  }

  InspectionReviewAccordionSectionData buildCapturedSection({
    required int capturedPendencias,
    required int capturedClassified,
    required int capturedTotal,
    required bool hasCapturedPending,
  }) {
    return InspectionReviewAccordionSectionData(
      isOk: !hasCapturedPending,
      subtitle:
          hasCapturedPending
              ? '$capturedPendencias pendência(s) de classificação • progresso $capturedClassified/$capturedTotal'
              : 'Todas as fotos capturadas estão classificadas • progresso $capturedClassified/$capturedTotal',
    );
  }

  InspectionReviewPendingShortcutData buildPendingShortcut({
    required String stage,
    String? subtipo,
  }) {
    final trimmedSubtype = subtipo?.trim();
    final hasSubtype = trimmedSubtype != null && trimmedSubtype.isNotEmpty;

    switch (stage) {
      case 'checkin':
        return const InspectionReviewPendingShortcutData(
          expandTechnicalPending: true,
          expandReview: false,
          expandCheckinAccordion: true,
          expandCapturedAccordion: false,
          expandClosing: false,
          expandedSubtype: null,
          target: InspectionReviewShortcutTargetData.checkinPending,
          scrollDelayMs: 220,
          snackbarMessage: 'Pendência aberta na seção de check-in.',
        );
      case 'capture':
        return InspectionReviewPendingShortcutData(
          expandTechnicalPending: true,
          expandReview: true,
          expandCheckinAccordion: false,
          expandCapturedAccordion: true,
          expandClosing: false,
          expandedSubtype: hasSubtype ? trimmedSubtype : null,
          target: InspectionReviewShortcutTargetData.capturedPhotos,
          scrollDelayMs: 220,
          snackbarMessage:
              hasSubtype
                  ? 'Pendência aberta na seção de revisão de fotos.'
                  : 'Pendência de captura aberta na seção de revisão de fotos.',
        );
      case 'review':
        return InspectionReviewPendingShortcutData(
          expandTechnicalPending: true,
          expandReview: true,
          expandCheckinAccordion: false,
          expandCapturedAccordion: true,
          expandClosing: false,
          expandedSubtype: hasSubtype ? trimmedSubtype : null,
          target: InspectionReviewShortcutTargetData.capturedPhotos,
          scrollDelayMs: 280,
          snackbarMessage: 'Pendência aberta na seção de revisão de fotos.',
        );
      case 'finalization':
        return const InspectionReviewPendingShortcutData(
          expandTechnicalPending: true,
          expandReview: false,
          expandCheckinAccordion: false,
          expandCapturedAccordion: false,
          expandClosing: true,
          expandedSubtype: null,
          target: InspectionReviewShortcutTargetData.closing,
          scrollDelayMs: 0,
          snackbarMessage: 'Pendência aberta na seção de encerramento.',
        );
    }

    return const InspectionReviewPendingShortcutData(
      expandTechnicalPending: false,
      expandReview: false,
      expandCheckinAccordion: false,
      expandCapturedAccordion: false,
      expandClosing: false,
      expandedSubtype: null,
      target: InspectionReviewShortcutTargetData.capturedPhotos,
      scrollDelayMs: 0,
      snackbarMessage: '',
    );
  }
}
