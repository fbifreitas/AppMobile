import '../config/checkin_step2_config.dart';
import '../models/inspection_review_models.dart';
import '../models/overlay_camera_capture_result.dart';
import '../models/job_status.dart';
import '../state/app_state.dart';
import 'checkin_dynamic_config_service.dart';

class InspectionReviewExportPayloadService {
  InspectionReviewExportPayloadService({
    CheckinDynamicConfigService? dynamicConfigService,
  }) : dynamicConfigService =
           dynamicConfigService ?? CheckinDynamicConfigService.instance;

  static final InspectionReviewExportPayloadService instance =
      InspectionReviewExportPayloadService();

  final CheckinDynamicConfigService dynamicConfigService;

  Map<String, dynamic> build({
    required AppState appState,
    required String assetType,
    required CheckinStep2Config step2Config,
    required List<OverlayCameraCaptureResult> captures,
    required List<InspectionReviewEditableCapture> reviewedItems,
    required String note,
    required String technicalJustification,
    bool freeCaptureMode = false,
  }) {
    final job = appState.jobAtual;
    return {
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'job': {
        'id': job?.id ?? '',
        'title': job?.title ?? '',
        'status': job?.status.label,
        'externalId': job?.externalId,
        'externalProtocol': job?.externalProtocol,
      },
      'step1': Map<String, dynamic>.from(appState.step1Payload),
      'step2': Map<String, dynamic>.from(appState.step2Payload),
      'step2Config': dynamicConfigService.serializeStep2Config(step2Config),
      'freeCaptureMode': freeCaptureMode,
      'manualClassificationRequired': freeCaptureMode,
      'review': {
        'assetType': assetType,
        'note': note.trim(),
        'technicalJustification': technicalJustification.trim(),
        'captures': captures
            .map(
              (capture) => {
                ...capture.toMap(),
                'classificationStatus': freeCaptureMode
                    ? 'pending_manual_classification'
                    : (capture.classificationConfirmed
                        ? 'classified'
                        : 'pending'),
              },
            )
            .toList(),
        'reviewedCaptures': reviewedItems
            .map(
              (item) => {
                'filePath': item.filePath,
                'targetItem': item.targetItem,
                'targetQualifier': item.targetQualifier,
                'material': item.materialAttribute,
                'conditionState': item.conditionState,
                'isComplete': freeCaptureMode
                    ? false
                    : item.status == InspectionReviewPhotoStatus.classified,
              },
            )
            .toList(),
      },
    };
  }
}
