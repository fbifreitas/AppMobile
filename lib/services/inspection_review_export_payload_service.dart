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
  }) {
    final job = appState.jobAtual;
    return {
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'job': {
        'id': job?.id ?? '',
        'title': job?.title ?? '',
        'titulo': job?.titulo ?? '',
        'status': job?.status.label,
        'externalId': job?.externalId,
        'idExterno': job?.idExterno,
        'externalProtocol': job?.externalProtocol,
        'protocoloExterno': job?.protocoloExterno,
      },
      'step1': Map<String, dynamic>.from(appState.step1Payload),
      'step2': Map<String, dynamic>.from(appState.step2Payload),
      'step2Config': dynamicConfigService.serializeStep2Config(step2Config),
      'review': {
        'assetType': assetType,
        'tipoImovel': assetType,
        'note': note.trim(),
        'observacao': note.trim(),
        'technicalJustification': technicalJustification.trim(),
        'justificativaTecnica': technicalJustification.trim(),
        'captures': captures.map((capture) => capture.toMap()).toList(),
        'capturas': captures.map((capture) => capture.toMap()).toList(),
        'reviewedCaptures': reviewedItems
            .map(
              (item) => {
                'filePath': item.filePath,
                'targetItem': item.targetItem,
                'targetQualifier': item.targetQualifier,
                'material': item.materialAttribute,
                'conditionState': item.conditionState,
                'isComplete':
                    item.status == InspectionReviewPhotoStatus.classified,
              },
            )
            .toList(),
        'capturasRevisadas': reviewedItems
            .map(
              (item) => {
                'filePath': item.filePath,
                'ambiente': item.ambiente,
                'elemento': item.elemento,
                'material': item.material,
                'estado': item.estado,
                'isComplete':
                    item.status == InspectionReviewPhotoStatus.classified,
              },
            )
            .toList(),
      },
    };
  }
}
