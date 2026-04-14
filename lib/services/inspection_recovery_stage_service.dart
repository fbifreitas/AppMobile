import '../models/inspection_recovery_stage.dart';

class InspectionRecoveryStageService {
  const InspectionRecoveryStageService();

  static const InspectionRecoveryStageService instance =
      InspectionRecoveryStageService();

  InspectionRecoveryStageSnapshot checkinStep1({
    required String jobId,
    required Map<String, dynamic> inspectionRecoveryPayload,
    required Map<String, dynamic> step1Payload,
    Map<String, dynamic> step2Payload = const <String, dynamic>{},
  }) {
    return InspectionRecoveryStageSnapshot(
      jobId: jobId,
      stage: InspectionRecoveryStageId.checkinStep1,
      payload: <String, dynamic>{
        ...inspectionRecoveryPayload,
        'step1': step1Payload,
        if (step2Payload.isNotEmpty) 'step2': step2Payload,
      },
    );
  }

  InspectionRecoveryStageSnapshot checkinStep2({
    required String jobId,
    required Map<String, dynamic> inspectionRecoveryPayload,
    required Map<String, dynamic> step1Payload,
    required Map<String, dynamic> step2Payload,
    Map<String, dynamic>? step2ConfigPayload,
  }) {
    return InspectionRecoveryStageSnapshot(
      jobId: jobId,
      stage: InspectionRecoveryStageId.checkinStep2,
      payload: <String, dynamic>{
        ...inspectionRecoveryPayload,
        'step1': step1Payload,
        'step2': step2Payload,
        if (step2ConfigPayload != null && step2ConfigPayload.isNotEmpty)
          'step2Config': step2ConfigPayload,
      },
    );
  }

  InspectionRecoveryStageSnapshot camera({
    required String jobId,
    required Map<String, dynamic> inspectionRecoveryPayload,
    required Map<String, dynamic> cameraStagePayload,
    required Map<String, dynamic> step1Payload,
    Map<String, dynamic> step2Payload = const <String, dynamic>{},
  }) {
    return InspectionRecoveryStageSnapshot(
      jobId: jobId,
      stage: InspectionRecoveryStageId.camera,
      payload: <String, dynamic>{
        ...inspectionRecoveryPayload,
        'cameraStage': cameraStagePayload,
        if (step1Payload.isNotEmpty) 'step1': step1Payload,
        if (step2Payload.isNotEmpty) 'step2': step2Payload,
      },
    );
  }

  InspectionRecoveryStageSnapshot review({
    required String jobId,
    required Map<String, dynamic> inspectionRecoveryPayload,
    required Map<String, dynamic> step1Payload,
    required Map<String, dynamic> step2Payload,
    required Map<String, dynamic> reviewPayload,
  }) {
    return InspectionRecoveryStageSnapshot(
      jobId: jobId,
      stage: InspectionRecoveryStageId.review,
      payload: <String, dynamic>{
        ...inspectionRecoveryPayload,
        'step1': step1Payload,
        'step2': step2Payload,
        'review': reviewPayload,
      },
    );
  }
}
