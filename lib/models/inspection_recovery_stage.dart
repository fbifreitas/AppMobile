import 'inspection_recovery_draft.dart';

enum InspectionRecoveryStageId {
  checkinStep1,
  checkinStep2,
  camera,
  review,
}

extension InspectionRecoveryStageIdExtension on InspectionRecoveryStageId {
  String get stageKey {
    switch (this) {
      case InspectionRecoveryStageId.checkinStep1:
        return 'checkin_step1';
      case InspectionRecoveryStageId.checkinStep2:
        return 'checkin_step2';
      case InspectionRecoveryStageId.camera:
        return 'camera';
      case InspectionRecoveryStageId.review:
        return 'inspection_review';
    }
  }

  String get stageLabel {
    switch (this) {
      case InspectionRecoveryStageId.checkinStep1:
        return 'Check-in etapa 1';
      case InspectionRecoveryStageId.checkinStep2:
        return 'Check-in etapa 2';
      case InspectionRecoveryStageId.camera:
        return 'Câmera';
      case InspectionRecoveryStageId.review:
        return 'Revisão final';
    }
  }

  String get routeName {
    switch (this) {
      case InspectionRecoveryStageId.checkinStep1:
        return '/checkin';
      case InspectionRecoveryStageId.checkinStep2:
        return '/checkin_step2';
      case InspectionRecoveryStageId.camera:
        return '/camera';
      case InspectionRecoveryStageId.review:
        return '/inspection_review';
    }
  }
}

class InspectionRecoveryStageSnapshot {
  const InspectionRecoveryStageSnapshot({
    required this.jobId,
    required this.stage,
    this.payload = const <String, dynamic>{},
  });

  final String jobId;
  final InspectionRecoveryStageId stage;
  final Map<String, dynamic> payload;

  InspectionRecoveryDraft toDraft() {
    return InspectionRecoveryDraft(
      jobId: jobId,
      stageKey: stage.stageKey,
      stageLabel: stage.stageLabel,
      routeName: stage.routeName,
      updatedAtIso: DateTime.now().toIso8601String(),
      payload: payload,
    );
  }
}

extension InspectionRecoveryDraftStageExtension on InspectionRecoveryDraft {
  InspectionRecoveryStageId get resolvedStage {
    switch (routeName.trim()) {
      case '/checkin':
        return InspectionRecoveryStageId.checkinStep1;
      case '/checkin_step2':
        return InspectionRecoveryStageId.checkinStep2;
      case '/camera':
        return InspectionRecoveryStageId.camera;
      case '/inspection_review':
        return InspectionRecoveryStageId.review;
    }

    switch (stageKey.trim()) {
      case 'checkin_step2':
        return InspectionRecoveryStageId.checkinStep2;
      case 'camera':
        return InspectionRecoveryStageId.camera;
      case 'inspection_review':
        return InspectionRecoveryStageId.review;
      case 'checkin':
      case 'checkin_step1':
      default:
        return InspectionRecoveryStageId.checkinStep1;
    }
  }
}
